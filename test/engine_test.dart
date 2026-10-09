import 'package:codebreaker/engine/codebreaker_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mastermind scoring (RULES.md §13)', () {
    test('all exact', () {
      expect(CodebreakerEngine.score([0, 1, 2, 3], [0, 1, 2, 3]), [4, 0]);
    });
    test('all misplaced', () {
      expect(CodebreakerEngine.score([3, 2, 1, 0], [0, 1, 2, 3]), [0, 4]);
    });
    test('mixed with duplicates', () {
      expect(CodebreakerEngine.score([0, 0, 1, 1], [0, 1, 2, 3]), [1, 1]);
    });
    test('no match', () {
      expect(CodebreakerEngine.score([0, 0, 0, 0], [1, 2, 3, 4]), [0, 0]);
    });
    test('two exact two misplaced', () {
      expect(CodebreakerEngine.score([1, 1, 2, 2], [1, 2, 1, 2]), [2, 2]);
    });
  });

  group('engine phases', () {
    test('solo starts in placing', () {
      final e = CodebreakerEngine(
        mode: CBMode.solo,
        difficulty: 0,
        crackerName: 'D',
        setterName: 'P',
        seed: 42,
      );
      expect(e.phase, CBPhase.placing);
      expect(e.pegs, 4);
      expect(e.colors, 6);
      expect(e.rows, 10);
      e.dispose();
    });

    test('codemaker starts in secretSet', () {
      final e = CodebreakerEngine(
        mode: CBMode.codemaker,
        difficulty: 0,
        crackerName: 'D',
        setterName: 'P',
        seed: 42,
      );
      expect(e.phase, CBPhase.secretSet);
      e.dispose();
    });

    test('check with incomplete row is ignored', () {
      final e = CodebreakerEngine(
        mode: CBMode.solo,
        difficulty: 0,
        crackerName: 'D',
        setterName: 'P',
        seed: 42,
      );
      e.placePeg(0);
      e.check();
      expect(e.phase, CBPhase.placing);
      expect(e.row, 0);
      e.dispose();
    });

    test('confirmSecret with incomplete draft is ignored', () {
      final e = CodebreakerEngine(
        mode: CBMode.codemaker,
        difficulty: 0,
        crackerName: 'D',
        setterName: 'P',
        seed: 42,
      );
      e.setSecretPeg(0);
      e.confirmSecret();
      expect(e.phase, CBPhase.secretSet);
      e.dispose();
    });

    test('difficulty specs', () {
      for (var d = 0; d < 3; d++) {
        final e = CodebreakerEngine(
          mode: CBMode.solo,
          difficulty: d,
          crackerName: 'D',
          setterName: 'P',
          seed: 1,
        );
        expect([e.pegs, e.colors, e.rows], difficultySpecs[d]);
        e.dispose();
      }
    });

    test('bot guess is full-length', () async {
      final e = CodebreakerEngine(
        mode: CBMode.vsBot,
        difficulty: 1,
        crackerName: 'Bot',
        setterName: 'P',
        seed: 7,
      );
      for (var i = 0; i < e.pegs; i++) {
        e.setSecretPeg(i % e.colors);
      }
      e.confirmSecret();
      // Bot thinking → placing → checking; wait for the check to land.
      for (var t = 0; t < 100 && e.phase != CBPhase.checking; t++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      expect(e.botGuess.length, e.pegs);
      e.dispose();
    });
  });
}
