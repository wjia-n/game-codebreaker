import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/codebreaker_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/vault_design.dart';
import '../theme/vault_themes.dart';

/// Game screen — the engine owns all phases; the UI only renders.
/// Every guess, peg drop and feedback pin animates visibly through the
/// engine's phase machine; results never pop instantly.
class GameScreen extends StatefulWidget {
  final CodebreakerEngine Function() engineFactory;
  final VaultAudio audio;
  final VaultSettings settings;
  final CBMode mode;
  final String modeLabel;

  const GameScreen({
    super.key,
    required this.engineFactory,
    required this.audio,
    required this.settings,
    required this.mode,
    required this.modeLabel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late CodebreakerEngine _e;
  bool _pausedUi = false;
  bool _reviewAsked = false;

  // Listener diffing for sound triggers.
  CBPhase _prevPhase = CBPhase.placing;
  int _prevPins = 0;
  int _prevBotPegs = 0;
  int _prevFilled = 0;

  VaultSettings get _s => widget.settings;
  VaultThemeDef get _t =>
      VaultThemes.byId(_s.themeId, custom: _s.customTheme);

  @override
  void initState() {
    super.initState();
    _e = widget.engineFactory();
    _prevPhase = _e.phase;
    _e.addListener(_onEngineChanged);
    widget.audio.startGameMusic();
    widget.audio.gameStart();
  }

  @override
  void dispose() {
    _e.removeListener(_onEngineChanged);
    _e.dispose();
    super.dispose();
  }

  void _onEngineChanged() {
    // Sound triggers on engine transitions.
    if (_e.phase != _prevPhase) {
      if (_e.phase == CBPhase.over) {
        if (_e.crackerWon) {
          widget.audio.win();
          _maybeRequestReview();
        } else {
          widget.audio.lose();
        }
        _recordStats();
      } else if (_e.phase == CBPhase.placing) {
        widget.audio.secretSet();
      }
      _prevPhase = _e.phase;
      _prevPins = 0;
      _prevBotPegs = 0;
    }
    if (_e.checkingProgress > _prevPins) {
      widget.audio.pinTick();
      _prevPins = _e.checkingProgress;
    }
    if (_e.botPlacingProgress > _prevBotPegs) {
      widget.audio.pegPlace();
      _prevBotPegs = _e.botPlacingProgress;
    }
    if (mounted) setState(() {});
  }

  void _recordStats() {
    final humanSideWon = _e.crackerWon &&
        (widget.mode == CBMode.solo ||
            widget.mode == CBMode.daily ||
            widget.mode == CBMode.codemaker);
    if (widget.mode == CBMode.daily) {
      _s.recordDaily(won: _e.crackerWon);
    } else {
      _s.recordGame(
        humanWon: humanSideWon,
        tries: _e.crackerWon ? _e.triesUsed : 0,
      );
    }
  }

  /// Real in-app review: only after a human-side win, at most once per day,
  /// and only when the quota naturally hits. Graceful when not from Play.
  Future<void> _maybeRequestReview() async {
    if (_reviewAsked || !_e.crackerWon) return;
    _reviewAsked = true;
    final humanWin = widget.mode == CBMode.solo ||
        widget.mode == CBMode.daily ||
        widget.mode == CBMode.codemaker;
    if (!humanWin) return;
    final milestone = widget.mode == CBMode.daily || _s.gamesPlayed % 4 == 0;
    if (!milestone) return;
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Not from Play / unavailable: stay silent, no fake UI.
    }
  }

  Future<void> _share() async {
    widget.audio.click();
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Can you crack the vault? Play Code Breaker with me! '
              'https://play.google.com/store/apps/details?id=com.gameswajiha.codebreaker',
        ),
      );
    } catch (_) {}
  }

  void _togglePause() {
    widget.audio.click();
    setState(() {
      _pausedUi = !_pausedUi;
      _e.setPaused(_pausedUi);
    });
  }

  void _playAgain() {
    widget.audio.click();
    _e.removeListener(_onEngineChanged);
    _e.dispose();
    setState(() {
      _e = widget.engineFactory();
      _prevPhase = _e.phase;
      _prevPins = 0;
      _prevBotPegs = 0;
      _prevFilled = 0;
      _pausedUi = false;
      _reviewAsked = false;
      _e.addListener(_onEngineChanged);
    });
    widget.audio.gameStart();
  }

  int _filledCount() {
    if (_e.phase == CBPhase.secretSet) {
      return _e.secretDraft.where((p) => p != -1).length;
    }
    if (_e.phase == CBPhase.placing && _e.row < _e.rows) {
      return _e.guesses[_e.row].where((p) => p != null).length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final filled = _filledCount();
    if (filled > _prevFilled) widget.audio.pegPlace();
    if (filled < _prevFilled) widget.audio.pegClear();
    _prevFilled = filled;

    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text(widget.modeLabel, style: Vault.display(20, theme: t)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _pausedUi ? Icons.play_arrow : Icons.pause,
                color: t.accentLight,
              ),
              onPressed: _togglePause,
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _SecretBar(engine: _e, theme: _t, settings: _s),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 16),
                    child: Text(
                      _e.banner,
                      style: Vault.body(14, theme: t),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: _e.rows,
                      itemBuilder: (ctx, displayIdx) {
                        final i = _e.rows - 1 - displayIdx;
                        return _GuessRow(
                          engine: _e,
                          rowIndex: i,
                          theme: t,
                          pegStyle: _s.pegStyle,
                          onSlotTap: _onSlotTap,
                        );
                      },
                    ),
                  ),
                  _buildTray(t),
                  _buildActionBar(t),
                ],
              ),
              if (_pausedUi) _PauseOverlay(theme: t, onResume: _togglePause),
              if (_e.over && !_pausedUi)
                _ResultOverlay(
                  theme: _t,
                  engine: _e,
                  settings: _s,
                  mode: widget.mode,
                  onPlayAgain: _playAgain,
                  onShare: _share,
                  onMenu: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSlotTap(int i) {
    if (_e.phase == CBPhase.secretSet) {
      _e.clearSecretSlot(i);
    } else {
      _e.clearSlot(i);
    }
  }

  Widget _buildTray(VaultThemeDef t) {
    final interactive = _e.canPlace || _e.canEditSecret;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (int c = 0; c < _e.colors; c++)
            GestureDetector(
              onTap: interactive
                  ? () {
                      if (_e.canEditSecret) {
                        _e.setSecretPeg(c);
                      } else {
                        _e.placePeg(c);
                      }
                    }
                  : null,
              child: Opacity(
                opacity: interactive ? 1.0 : 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Peg(
                      color: t.pegColors[c],
                      style: _s.pegStyle,
                      size: 42,
                      theme: t,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.pegNames[c],
                      style: Vault.label(9, theme: t),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(VaultThemeDef t) {
    String label;
    bool ready;
    VoidCallback action;
    if (_e.phase == CBPhase.secretSet) {
      ready = _e.secretReady;
      label = ready ? 'Lock it in 🔒' : 'Pick ${_e.pegs} pegs…';
      action = () {
        widget.audio.secretSet();
        _e.confirmSecret();
      };
    } else if (_e.phase == CBPhase.placing && _e.humanCracks) {
      ready = _e.inputReady;
      label = _e.over
          ? 'Done'
          : (ready ? 'Check guess 🔍' : 'Build your guess…');
      action = () {
        widget.audio.click();
        _e.check();
      };
    } else {
      // Bot is working or game is over: show a waiting state, never a dead button.
      ready = false;
      label = _e.over ? 'Case closed' : 'Working…';
      action = () {};
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: VaultButton(
        label: label,
        theme: t,
        width: 250,
        fontSize: 17,
        onTap: () {
          if (!ready || _e.over) {
            if (!_e.over && !ready) widget.audio.invalid();
            return;
          }
          action();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// The vault's secret: hidden while cracking, revealed at the end.
/// During secretSet it shows the code being built.
class _SecretBar extends StatelessWidget {
  final CodebreakerEngine engine;
  final VaultThemeDef theme;
  final VaultSettings settings;
  const _SecretBar({
    required this.engine,
    required this.theme,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final revealed = e.over;
    final editing = e.phase == CBPhase.secretSet;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.9),
            theme.woodDeep.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔐 ', style: TextStyle(fontSize: 18, color: theme.ivory)),
          for (int i = 0; i < e.pegs; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: editing
                  ? GestureDetector(
                      onTap: () => e.clearSecretSlot(i),
                      child: Peg(
                        color: e.secretDraft[i] == -1
                            ? Colors.transparent
                            : theme.pegColors[e.secretDraft[i]],
                        empty: e.secretDraft[i] == -1,
                        style: settings.pegStyle,
                        size: 32,
                        theme: theme,
                      ),
                    )
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      child: Peg(
                        color: revealed
                            ? theme.pegColors[e.secret[i]]
                            : Colors.transparent,
                        empty: !revealed,
                        style: settings.pegStyle,
                        size: 32,
                        theme: theme,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// One board row: guess sockets + feedback pins.
class _GuessRow extends StatelessWidget {
  final CodebreakerEngine engine;
  final int rowIndex;
  final VaultThemeDef theme;
  final int pegStyle;
  final void Function(int) onSlotTap;
  const _GuessRow({
    required this.engine,
    required this.rowIndex,
    required this.theme,
    required this.pegStyle,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final i = rowIndex;
    final isCurrent = i == e.row && !e.over;
    final blacks = e.feedback[i][0], whites = e.feedback[i][1];
    // How many pins are visibly revealed on this row right now.
    int pinsShown;
    if (i < e.row || e.over) {
      pinsShown = e.pegs;
    } else if (i == e.row && e.phase == CBPhase.checking) {
      pinsShown = e.checkingProgress;
    } else {
      pinsShown = 0;
    }
    final interactive =
        isCurrent && e.phase == CBPhase.placing && e.humanCracks;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.accent.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(color: theme.accent, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${i + 1}',
            style: Vault.label(11, theme: theme),
          ),
          const SizedBox(width: 6),
          for (int k = 0; k < e.pegs; k++)
            GestureDetector(
              onTap: interactive ? () => onSlotTap(k) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Peg(
                    key: ValueKey('${e.guesses[i][k]}'),
                    color: e.guesses[i][k] == null
                        ? Colors.transparent
                        : theme.pegColors[e.guesses[i][k]!],
                    empty: e.guesses[i][k] == null,
                    style: pegStyle,
                    size: 34,
                    theme: theme,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int k = 0; k < e.pegs; k++)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: FeedbackPin(
                      key: ValueKey('pin$i-$k-${k < pinsShown ? (k < blacks ? 1 : (k < blacks + whites ? 2 : 0)) : 0}'),
                      kind: k < pinsShown
                          ? (k < blacks
                              ? 1
                              : (k < blacks + whites ? 2 : 0))
                          : 0,
                      size: 13,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _PauseOverlay extends StatelessWidget {
  final VaultThemeDef theme;
  final VoidCallback onResume;
  const _PauseOverlay({required this.theme, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: Vault.display(34, theme: theme)),
            const SizedBox(height: 8),
            Text('The vault waits for you.',
                style: Vault.body(15, theme: theme)),
            const SizedBox(height: 22),
            VaultButton(label: '▶  Resume', onTap: onResume, theme: theme),
            const SizedBox(height: 12),
            VaultButton(
              label: 'Leave case',
              theme: theme,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _ResultOverlay extends StatelessWidget {
  final VaultThemeDef theme;
  final CodebreakerEngine engine;
  final VaultSettings settings;
  final CBMode mode;
  final VoidCallback onPlayAgain;
  final VoidCallback onShare;
  final VoidCallback onMenu;
  const _ResultOverlay({
    required this.theme,
    required this.engine,
    required this.settings,
    required this.mode,
    required this.onPlayAgain,
    required this.onShare,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final humanSideWon = e.crackerWon &&
        (mode == CBMode.solo ||
            mode == CBMode.daily ||
            mode == CBMode.codemaker);
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.woodMid, theme.woodDeep],
              ),
              border: Border.all(color: theme.accent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.crackerWon ? '🔓' : '🔐',
                  style: const TextStyle(fontSize: 44),
                ),
                const SizedBox(height: 8),
                Text(
                  e.crackerWon ? engine.banner : 'The vault wins this round.',
                  style: Vault.display(24, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e.crackerWon
                      ? (mode == CBMode.vsBot
                          ? 'The bot cracked ${engine.setterName}\'s code in ${e.triesUsed} tries.'
                          : '${engine.crackerName} cracked it in ${e.triesUsed} ${e.triesUsed == 1 ? 'try' : 'tries'}!')
                      : 'Better luck next time, detective.',
                  style: Vault.body(14, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (humanSideWon && settings.streak > 1)
                  Text(
                    '🔥 Win streak: ${settings.streak}',
                    style: Vault.label(14, theme: theme),
                  ),
                const SizedBox(height: 18),
                VaultButton(
                  label: '↻  Play again',
                  onTap: onPlayAgain,
                  theme: theme,
                  width: 220,
                  fontSize: 16,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SmallBtn(
                        theme: theme,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: onShare),
                    const SizedBox(width: 12),
                    _SmallBtn(
                        theme: theme,
                        icon: Icons.home,
                        label: 'Menu',
                        onTap: onMenu),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final VaultThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accentLight, size: 18),
            const SizedBox(width: 6),
            Text(label, style: Vault.label(13, theme: theme)),
          ],
        ),
      ),
    );
  }
}
