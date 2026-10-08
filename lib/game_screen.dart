import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

const _pegs = 4;
const _maxGuesses = 10;
const _codeColors = <Color>[
  Color(0xFFE5484D),
  Color(0xFFFF9F2E),
  Color(0xFFFFD60A),
  Color(0xFF30D158),
  Color(0xFF0A84FF),
  Color(0xFFBF5AF2),
];

class CodeBreakerScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const CodeBreakerScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<CodeBreakerScreen> createState() => _CodeBreakerScreenState();
}

class _CodeBreakerScreenState extends State<CodeBreakerScreen> {
  final _rnd = Random();
  late List<int> _secret;
  List<List<int?>> _guesses = [];
  List<List<int>> _feedback = []; // per row: [blacks, whites]
  int _row = 0;
  bool _over = false;
  bool _won = false;
  int _games = 0, _wins = 0, _best = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _games = p.getInt('cb_games') ?? 0;
        _wins = p.getInt('cb_wins') ?? 0;
        _best = p.getInt('cb_best') ?? 0;
      });
    });
  }

  void _newGame() {
    _secret = List.generate(_pegs, (_) => _rnd.nextInt(6));
    _guesses = List.generate(_maxGuesses, (_) => List.filled(_pegs, null));
    _feedback = List.generate(_maxGuesses, (_) => [0, 0]);
    _row = 0;
    _over = false;
    _won = false;
  }

  void _placePeg(int color) {
    if (_over) return;
    final row = _guesses[_row];
    final i = row.indexWhere((p) => p == null);
    if (i == -1) return;
    setState(() => row[i] = color);
    Sfx.tap();
  }

  void _clearSlot(int i) {
    if (_over) return;
    if (_guesses[_row][i] != null) {
      setState(() => _guesses[_row][i] = null);
      Sfx.tap();
    }
  }

  List<int> _scoreGuess(List<int> guess) {
    int blacks = 0, whites = 0;
    final sLeft = <int>[], gLeft = <int>[];
    for (int i = 0; i < _pegs; i++) {
      if (guess[i] == _secret[i]) {
        blacks++;
      } else {
        sLeft.add(_secret[i]);
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

  Future<void> _saveStats() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('cb_games', _games);
    await p.setInt('cb_wins', _wins);
    await p.setInt('cb_best', _best);
  }

  void _check() {
    if (_over) return;
    final row = _guesses[_row];
    if (row.any((p) => p == null)) return;
    final guess = row.map((p) => p!).toList();
    final fb = _scoreGuess(guess);
    setState(() {
      _feedback[_row] = fb;
      _row++;
      _games++;
    });
    if (fb[0] == _pegs) {
      Sfx.win();
      _wins++;
      if (_best == 0 || _row < _best) _best = _row;
      _saveStats();
      setState(() {
        _over = true;
        _won = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _over != true) return;
        widget.callbacks.finish(
          headline: '🔐 Cracked in $_row tries!',
          subline: 'The vault surrenders its secrets to you.',
        );
      });
    } else if (_row >= _maxGuesses) {
      Sfx.lose();
      _saveStats();
      setState(() {
        _over = true;
        _won = false;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        widget.callbacks.finish(
          headline: 'The code held its secrets…',
          subline: 'Try again, detective. The vault is waiting.',
        );
      });
    } else {
      Sfx.move();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    final ready = _guesses[_row].every((p) => p != null) && !_over;
    return Column(
      children: [
        _SecretBar(secret: _secret, revealed: _over, theme: theme),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            _games == 0
                ? 'Your first case — good luck, detective 🕵️'
                : 'Cases: $_games   Solved: $_wins${_best > 0 ? '   Best: $_best tries' : ''}',
            style: TextStyle(color: theme.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            shrinkWrap: true,
            itemCount: _maxGuesses,
            itemBuilder: (ctx, displayIdx) {
              final i = _maxGuesses - 1 - displayIdx;
              final isCurrent = i == _row && !_over;
              return _GuessRow(
                guess: _guesses[i],
                feedback: _feedback[i],
                locked: i < _row || _over,
                isCurrent: isCurrent,
                theme: theme,
                onSlotTap: _clearSlot,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            spacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (int c = 0; c < 6; c++)
                GestureDetector(
                  onTap: () => _placePeg(c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _codeColors[c],
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.text.withValues(alpha: 0.4), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: WajihaButton(
            label: _over ? (_won ? 'Cracked! 🎉' : 'Case closed') : 'Check guess 🔍',
            emoji: '',
            primary: ready,
            onTap: ready ? _check : () {},
          ),
        ),
      ],
    );
  }
}

class _SecretBar extends StatelessWidget {
  final List<int> secret;
  final bool revealed;
  final GameTheme theme;
  const _SecretBar(
      {required this.secret, required this.revealed, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: theme.radius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔐 ', style: TextStyle(fontSize: 18)),
          for (final c in secret)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: revealed ? _codeColors[c] : theme.background,
                shape: BoxShape.circle,
                border: Border.all(color: theme.primary, width: 2),
              ),
              child: revealed
                  ? null
                  : Center(
                      child: Text('?',
                          style: TextStyle(color: theme.muted, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
    );
  }
}

class _GuessRow extends StatelessWidget {
  final List<int?> guess;
  final List<int> feedback;
  final bool locked;
  final bool isCurrent;
  final GameTheme theme;
  final void Function(int) onSlotTap;
  const _GuessRow(
      {required this.guess,
      required this.feedback,
      required this.locked,
      required this.isCurrent,
      required this.theme,
      required this.onSlotTap});

  @override
  Widget build(BuildContext context) {
    final blacks = feedback[0], whites = feedback[1];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: isCurrent ? theme.primary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrent ? Border.all(color: theme.primary, width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _pegs; i++)
            GestureDetector(
              onTap: isCurrent ? () => onSlotTap(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: guess[i] == null
                      ? theme.surface
                      : _codeColors[guess[i]!],
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: guess[i] == null ? theme.muted : theme.text,
                      width: guess[i] == null ? 1.5 : 2.5),
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
                for (int k = 0; k < _pegs; k++)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: locked
                          ? (k < blacks
                              ? Colors.black
                              : (k < blacks + whites ? Colors.white : theme.surface))
                          : theme.surface,
                      border: Border.all(color: theme.muted, width: 1),
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
