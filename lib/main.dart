import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const CodeBreakerApp());

class CodeBreakerApp extends StatelessWidget {
  const CodeBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Code Breaker',
      tagline: 'Crack the secret color code before you run out of guesses',
      emoji: '🕵️',
      slug: 'codebreaker',
      howToPlay:
          '• The vault hides a secret 4-peg code from 6 colors.\n• Build a guess, then tap Check. ⚫ = right color in the right spot, ⚪ = right color, wrong spot.\n• 10 guesses to crack it. Think like a detective!\n• Win streaks and best tries are saved.',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          CodeBreakerScreen(players: players, callbacks: cb),
    );
  }
}
