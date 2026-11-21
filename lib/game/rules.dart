import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';
import 'match_engine.dart';

class MatchRules extends GameRules<MatchLevel> {
  @override
  String get gameId => 'game-009-number-match';

  @override
  List<String> get optionalMechanics => const ['limited_adds', 'timer', 'big'];

  @override
  List<GameModeId> get modes => const [
        GameModeId.campaign,
        GameModeId.endless,
        GameModeId.timeAttack,
        GameModeId.zen,
        GameModeId.daily,
        GameModeId.weekly,
        GameModeId.challenge,
      ];

  @override
  List<GameStat> get gameStats => const [
        GameStat('pairs_matched', 'Eşleşen çift', 'Pairs matched', scale: 100),
        GameStat('rows_cleared', 'Silinen satır', 'Rows cleared', scale: 20),
        GameStat('boards_cleared', 'Temizlenen tahta', 'Boards cleared', scale: 5),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('pairs', 'pairs_matched', [40, 100, 200]),
        MissionTemplate('rows', 'rows_cleared', [5, 12, 25]),
      ];

  @override
  MatchLevel generate(LevelSpec spec) => generateMatch(spec);

  @override
  Validation validate(MatchLevel l, LevelSpec spec) {
    if (l.start.isEmpty || l.start.length.isOdd) return const Validation.fail('shape');
    if (l.start.any((d) => d < 1 || d > 9)) return const Validation.fail('digits');
    if (!solvableMatch(l)) return const Validation.fail('not clearable');
    return Validation.ok(l.start.length ~/ 2);
  }

  static int stars(MatchGame g) {
    if (!g.won) return 0;
    final used = g.level.adds - g.addsLeft;
    if (used == 0) return 3;
    if (used <= 2) return 2;
    return 1;
  }
}

GameRules createRules() => MatchRules();
