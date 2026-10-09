import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Modes & phases
// ---------------------------------------------------------------------------

/// Game modes:
/// - solo: the vault hides a secret; the human cracks it.
/// - vsBot: the human sets a secret; the bot cracks it (watch it work).
/// - codemaker: 2-player pass-and-play — player 1 sets, player 2 cracks.
/// - daily: like solo, but the secret is seeded from today's date.
enum CBMode { solo, vsBot, codemaker, daily }

/// Turn phases owned entirely by the engine. The UI only renders.
/// [secretSet] = a human is choosing the secret code (vsBot / codemaker).
/// [placing] = the cracker is building a guess.
/// [botThinking] = the bot is choosing its next guess (vsBot).
/// [botPlacing] = the bot's guess pegs drop one by one (visible).
/// [checking] = feedback pins are being revealed one by one (visible).
/// [resolving] = short beat before the next row.
/// [over] = game finished.
enum CBPhase {
  secretSet,
  placing,
  botThinking,
  botPlacing,
  checking,
  resolving,
  over,
}

/// Difficulty specs: [pegs, colors, rows].
/// Easy 4/6/10, Medium 5/7/12, Hard 6/8/14 (RULES.md §2).
const difficultySpecs = [
  [4, 6, 10],
  [5, 7, 12],
  [6, 8, 14],
];

// ---------------------------------------------------------------------------
// Engine: deterministic rules, state, bot AI. UI-agnostic.
// ---------------------------------------------------------------------------
class CodebreakerEngine extends ChangeNotifier {
  final CBMode mode;
  final int difficulty; // 0 easy, 1 medium, 2 hard
  final String crackerName;
  final String setterName;

  late final int pegs;
  late final int colors;
  late final int rows;

  late List<int> secret;
  late List<List<int?>> guesses; // rows x pegs; current row may be partial
  late List<List<int>> feedback; // per row: [blacks, whites]
  late List<int> secretDraft; // code being set during secretSet

  int row = 0;
  CBPhase phase = CBPhase.placing;
  int checkingProgress = 0; // feedback pins revealed so far
  int botPlacingProgress = 0; // bot pegs dropped so far
  List<int> botGuess = [];
  bool over = false;
  bool crackerWon = false;
  String banner = '';

  /// Consistent-code history for the bot: (guess, blacks, whites).
  final List<List<int>> _historyGuesses = [];
  final List<List<int>> _historyFeedback = [];

  final Random _rand;
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  /// Test hook: when set, the secret uses this code. Consumed on newGame.
  @visibleForTesting
  List<int>? forcedSecret;

  CodebreakerEngine({
    required this.mode,
    required this.difficulty,
    required this.crackerName,
    required this.setterName,
    int? seed,
  }) : _rand = seed == null ? Random() : Random(seed) {
    final spec = difficultySpecs[difficulty.clamp(0, 2)];
    pegs = spec[0];
    colors = spec[1];
    rows = spec[2];
    _newGame();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
  }

  bool get humanCracks => mode == CBMode.solo || mode == CBMode.daily || mode == CBMode.codemaker;
  bool get botCracks => mode == CBMode.vsBot;

  void _newGame() {
    if (forcedSecret != null &&
        forcedSecret!.length == pegs &&
        forcedSecret!.every((c) => c >= 0 && c < colors)) {
      secret = List.of(forcedSecret!);
    } else {
      secret = List.generate(pegs, (_) => _rand.nextInt(colors));
    }
    guesses = List.generate(rows, (_) => List<int?>.filled(pegs, null));
    feedback = List.generate(rows, (_) => [0, 0]);
    // secretDraft uses -1 for empty sockets.
    secretDraft = List.filled(pegs, -1);
    row = 0;
    checkingProgress = 0;
    botPlacingProgress = 0;
    botGuess = [];
    over = false;
    crackerWon = false;
    _historyGuesses.clear();
    _historyFeedback.clear();
    if (mode == CBMode.vsBot || mode == CBMode.codemaker) {
      phase = CBPhase.secretSet;
      banner = '$setterName, set your secret code…';
    } else {
      phase = CBPhase.placing;
      banner = 'Crack the code, $crackerName!';
    }
  }

  // ------------------------------------------------------------ scoring
  /// Standard Mastermind scoring: [blacks, whites].
  static List<int> score(List<int> guess, List<int> secret) {
    int blacks = 0, whites = 0;
    final sLeft = <int>[], gLeft = <int>[];
    for (int i = 0; i < secret.length; i++) {
      if (guess[i] == secret[i]) {
        blacks++;
      } else {
        sLeft.add(secret[i]);
        gLeft.add(guess[i]);
      }
    }
    for (final c in gLeft) {
      if (sLeft.contains(c)) {
        whites++;
        sLeft.remove(c);
      }
    }
    return [blacks, whites];
  }

  // ------------------------------------------------------------ timers
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms via recovery.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// Stuck states are impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    switch (phase) {
      case CBPhase.checking:
        // Pins stalled mid-reveal: finish instantly, then settle.
        checkingProgress = pegs;
        _afterCheck();
        break;
      case CBPhase.botPlacing:
        botPlacingProgress = botGuess.length;
        _beginCheck();
        break;
      case CBPhase.botThinking:
        _botChoose();
        break;
      case CBPhase.resolving:
        _afterResolve();
        break;
      case CBPhase.secretSet:
      case CBPhase.placing:
      case CBPhase.over:
        break; // awaiting human input — a legal idle state
    }
  }

  // ------------------------------------------------------------ secret set
  bool get canEditSecret => phase == CBPhase.secretSet && !over;

  void setSecretPeg(int color) {
    if (!canEditSecret) return;
    final i = secretDraft.indexWhere((p) => p == -1);
    if (i == -1) return;
    secretDraft[i] = color.clamp(0, colors - 1);
    notifyListeners();
  }

  void clearSecretSlot(int i) {
    if (!canEditSecret) return;
    if (secretDraft[i] != -1) {
      secretDraft[i] = -1;
      notifyListeners();
    }
  }

  bool get secretReady => secretDraft.every((p) => p != -1);

  /// Lock the human-set secret in and start cracking.
  void confirmSecret() {
    if (!canEditSecret || !secretReady) return;
    secret = List.of(secretDraft);
    if (mode == CBMode.vsBot) {
      phase = CBPhase.botThinking;
      banner = 'The bot studies the vault…';
      notifyListeners();
      _arm(const Duration(milliseconds: 900), _botChoose);
    } else {
      phase = CBPhase.placing;
      banner = '$crackerName, crack $setterName\'s code!';
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ human play
  bool get canPlace =>
      phase == CBPhase.placing && humanCracks && !over;

  List<int?> get currentInput => guesses[row];

  void placePeg(int color) {
    if (!canPlace) return;
    final r = guesses[row];
    final i = r.indexWhere((p) => p == null);
    if (i == -1) return;
    r[i] = color.clamp(0, colors - 1);
    notifyListeners();
  }

  void clearSlot(int i) {
    if (!canPlace) return;
    if (guesses[row][i] != null) {
      guesses[row][i] = null;
      notifyListeners();
    }
  }

  bool get inputReady => canPlace && guesses[row].every((p) => p != null);

  /// Submit the current guess. Input locks immediately; feedback pins are
  /// revealed one by one — never popped instantly.
  void check() {
    if (!inputReady) return;
    phase = CBPhase.checking;
    checkingProgress = 0;
    final guess = guesses[row].map((p) => p!).toList();
    feedback[row] = score(guess, secret);
    notifyListeners();
    _arm(const Duration(milliseconds: 150), _revealPin);
  }

  void _revealPin() {
    if (over || phase != CBPhase.checking) return;
    checkingProgress++;
    notifyListeners();
    if (checkingProgress < pegs) {
      _arm(const Duration(milliseconds: 140), _revealPin);
    } else {
      _afterCheck();
    }
  }

  void _afterCheck() {
    if (over) return;
    final fb = feedback[row];
    if (fb[0] == pegs) {
      _finish(true);
      return;
    }
    row++;
    if (row >= rows) {
      _finish(false);
      return;
    }
    phase = CBPhase.resolving;
    notifyListeners();
    _arm(const Duration(milliseconds: 380), _afterResolve);
  }

  void _afterResolve() {
    if (over || phase != CBPhase.resolving) return;
    if (botCracks) {
      phase = CBPhase.botThinking;
      banner = 'The bot studies the vault…';
      notifyListeners();
      _arm(const Duration(milliseconds: 850), _botChoose);
    } else {
      phase = CBPhase.placing;
      banner = 'Row ${row + 1} — think, $crackerName!';
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ bot play
  void _botChoose() {
    if (over || phase != CBPhase.botThinking) return;
    botGuess = _botNextGuess();
    botPlacingProgress = 0;
    phase = CBPhase.botPlacing;
    banner = 'The bot places its guess…';
    notifyListeners();
    _arm(const Duration(milliseconds: 220), _botDropPeg);
  }

  void _botDropPeg() {
    if (over || phase != CBPhase.botPlacing) return;
    botPlacingProgress++;
    // Mirror into the visible row so the board renders it.
    for (int i = 0; i < botPlacingProgress && i < pegs; i++) {
      guesses[row][i] = botGuess[i];
    }
    notifyListeners();
    if (botPlacingProgress < pegs) {
      _arm(const Duration(milliseconds: 170), _botDropPeg);
    } else {
      _beginCheck();
    }
  }

  void _beginCheck() {
    if (over) return;
    phase = CBPhase.checking;
    checkingProgress = 0;
    feedback[row] = score(botGuess, secret);
    _historyGuesses.add(List.of(botGuess));
    _historyFeedback.add(List.of(feedback[row]));
    notifyListeners();
    _arm(const Duration(milliseconds: 150), _revealPin);
  }

  /// Bot guess strategy (RULES.md §11):
  /// - Easy: mostly random probes with a little memory.
  /// - Medium: random code consistent with all feedback so far.
  /// - Hard: minimax-lite over consistent candidates.
  List<int> _botNextGuess() {
    final pool = _candidatePool();
    final consistent =
        pool.where((g) => _isConsistent(g)).toList(growable: false);
    final candidates = consistent.isEmpty ? pool : consistent;
    switch (difficulty) {
      case 0: // Easy: sometimes a wild guess.
        if (candidates.isNotEmpty && _rand.nextDouble() < 0.7) {
          return List.of(candidates[_rand.nextInt(candidates.length)]);
        }
        return List.generate(pegs, (_) => _rand.nextInt(colors));
      case 2: // Hard: minimax-lite.
        return _minimaxPick(candidates);
      default: // Medium: any consistent code.
        return List.of(candidates[_rand.nextInt(candidates.length)]);
    }
  }

  List<List<int>>? _poolCache;

  /// Full code space, or a bounded sample when the space is huge
  /// (hard mode 8^6 = 262144 would be too heavy).
  List<List<int>> _candidatePool() {
    if (_poolCache != null) return _poolCache!;
    var total = 1;
    for (int i = 0; i < pegs; i++) {
      total *= colors;
    }
    List<List<int>> pool;
    if (total <= 20000) {
      pool = List.generate(total, (n) {
        var m = n;
        final g = List<int>.filled(pegs, 0);
        for (int i = pegs - 1; i >= 0; i--) {
          g[i] = m % colors;
          m ~/= colors;
        }
        return g;
      });
    } else {
      // Bounded sample for huge spaces; always include a classic opener.
      final set = <String>{};
      pool = [];
      final opener = [0, 0, 1, 1, 2, 2].sublist(0, pegs);
      pool.add(List.of(opener));
      set.add(opener.join(','));
      while (pool.length < 4096) {
        final g = List.generate(pegs, (_) => _rand.nextInt(colors));
        final k = g.join(',');
        if (set.add(k)) pool.add(g);
      }
    }
    _poolCache = pool;
    return pool;
  }

  bool _isConsistent(List<int> g) {
    for (int h = 0; h < _historyGuesses.length; h++) {
      final fb = score(g, _historyGuesses[h]);
      final want = _historyFeedback[h];
      if (fb[0] != want[0] || fb[1] != want[1]) return false;
    }
    return true;
  }

  /// Minimax-lite: pick the candidate minimizing the worst-case remaining
  /// candidates, scored against a bounded sample of possible secrets.
  List<int> _minimaxPick(List<List<int>> candidates) {
    if (candidates.length <= 2) {
      return List.of(candidates[_rand.nextInt(candidates.length)]);
    }
    final probeSet = candidates.length > 400
        ? [for (int i = 0; i < 400; i++) candidates[_rand.nextInt(candidates.length)]]
        : candidates;
    final guessSet = candidates.length > 400
        ? [for (int i = 0; i < 400; i++) candidates[_rand.nextInt(candidates.length)]]
        : candidates;
    var best = guessSet[0];
    var bestWorst = 1 << 30;
    for (final g in guessSet) {
      final partitions = <String, int>{};
      var worst = 0;
      for (final s in probeSet) {
        final fb = score(g, s);
        final k = '${fb[0]}:${fb[1]}';
        final v = (partitions[k] ?? 0) + 1;
        partitions[k] = v;
        if (v > worst) {
          worst = v;
          if (worst >= bestWorst) break; // can't beat current best
        }
      }
      if (worst < bestWorst) {
        bestWorst = worst;
        best = g;
        if (bestWorst <= 1) break;
      }
    }
    return List.of(best);
  }

  // ------------------------------------------------------------ finish
  void _finish(bool won) {
    over = true;
    crackerWon = won;
    phase = CBPhase.over;
    checkingProgress = pegs;
    banner = won
        ? 'Cracked in ${row + 1} ${row == 0 ? 'try' : 'tries'}! 🎉'
        : 'The code held its secrets…';
    notifyListeners();
  }

  /// Tries used by the cracker (for stats).
  int get triesUsed => row + 1;
}
