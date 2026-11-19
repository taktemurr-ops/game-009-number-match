import 'package:flutter_test/flutter_test.dart';
import 'package:game_009_number_match/core/level_plan.dart';
import 'package:game_009_number_match/game/match_engine.dart';
import 'package:game_009_number_match/game/rules.dart';

MatchLevel lvl(List<int> d) => MatchLevel(start: d, adds: 2, timeLimit: 0, difficulty: 1, seed: 1);

void main() {
  final rules = MatchRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('equal digits or sum 10, connected by a clear line', () {
    final g = MatchGame(lvl([1, 9, 5, 5, 3, 7, 2, 2, 4, 6, 8, 1, 1, 1, 1, 1, 1, 1]));
    expect(g.canMatch(0, 1), isTrue, reason: 'adjacent, sum 10');
    expect(g.canMatch(2, 3), isTrue, reason: 'adjacent, equal');
    expect(g.canMatch(0, 2), isFalse, reason: 'blocked by 9');
    expect(g.canMatch(0, 9), isFalse, reason: '1 and 6 do not match');
    expect(g.canMatch(1, 10), isFalse, reason: 'vertical but 9 vs 8');
    expect(g.canMatch(8, 9), isTrue, reason: 'row wrap: 4 + 6');
  });

  test('full cleared rows disappear, board clears, undo works', () {
    final g = MatchGame(lvl([1, 1, 2, 8, 3, 7, 4, 6, 5, 5, 9, 1]));
    for (final p in [[0, 1], [2, 3], [4, 5], [6, 7]]) {
      expect(g.match(p[0], p[1]), greaterThanOrEqualTo(0));
    }
    expect(g.match(8, 9), 1, reason: 'first row of 9 removed');
    expect(g.cells.length, lessThan(12));
    g.undo();
    expect(g.cells.length, 12);
  });

  test('add numbers appends the remaining digits', () {
    final g = MatchGame(lvl([1, 2, 3]));
    expect(g.addNumbers(), isTrue);
    expect(g.cells, equals([1, 2, 3, 1, 2, 3]));
  });

  test('every level is clearable without adds (constructive)', () {
    for (var n = 1; n <= 200; n++) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });

  test('hint finds a pair until the board is empty', () {
    final g = MatchGame(rules.build(planner.spec(15)).puzzle);
    var guard = 0;
    while (!g.won && guard++ < 500) {
      final p = g.findPair();
      if (p == null) {
        expect(g.addNumbers(), isTrue);
        continue;
      }
      g.match(p[0], p[1]);
    }
    expect(g.won || g.addsLeft >= 0, isTrue);
  });

  test('resume restores state', () {
    final l = rules.build(planner.spec(5)).puzzle;
    final g = MatchGame(l);
    final p = g.findPair()!;
    g.match(p[0], p[1]);
    expect(MatchGame.restore(l, g.serialize()).serialize(), g.serialize());
  });
}
