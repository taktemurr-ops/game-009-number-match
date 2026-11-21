import 'package:flutter/material.dart';

import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';
import 'match_engine.dart';
import 'rules.dart';

class MatchView extends StatefulWidget {
  final PlayContext ctx;
  const MatchView({super.key, required this.ctx});

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> with RoundClock {
  late MatchGame game;
  int? _sel;
  List<int>? _hint;
  int _hints = 0;
  int _undos = 0;
  int _solved = 0;
  int _pairsTotal = 0;
  int _rowsTotal = 0;
  int _scoreCarry = 0;
  bool _ended = false;

  PlayContext get ctx => widget.ctx;
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack, GameModeId.zen].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    final level = (ctx.generated as GeneratedLevel<MatchLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? MatchGame.restore(level, snap) : MatchGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _solved = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    _scoreCarry = (ctx.resume['carry'] as num?)?.toInt() ?? 0;
    startClock(initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0, limit: level.timeLimit);
  }

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end(_chain ? (_solved > 0 || _score > 0) : game.won);

  int get _score => _scoreCarry + game.score;

  void _persist() => ctx.saveResume({
        'snap': game.serialize(),
        'secs': seconds,
        'hints': _hints,
        'solved': _solved,
        'carry': _scoreCarry,
      });

  void _tap(int i) {
    if (_ended || game.cells[i] == 0) return;
    final s = _sel;
    if (s == null || s == i) {
      setState(() => _sel = s == i ? null : i);
      ctx.sfx(Sfx.tap);
      return;
    }
    if (!game.canMatch(s, i)) {
      ctx.sfx(Sfx.error);
      setState(() => _sel = i);
      return;
    }
    final rows = game.match(s, i);
    _pairsTotal++;
    _rowsTotal += rows;
    _sel = null;
    _hint = null;
    ctx.sfx(rows > 0 ? Sfx.combo : Sfx.clear);
    setState(() {});
    _persist();
    _check();
  }

  Future<void> _check() async {
    if (game.won) {
      if (_chain) {
        _solved++;
        _scoreCarry += game.score + 500;
        final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _solved]));
        setState(() => game = MatchGame(MatchRules().build(next).puzzle));
        _persist();
        return;
      }
      _end(true);
      return;
    }
    if (game.stuck) {
      if (ctx.spec.mode == GameModeId.zen) {
        setState(game.bonusAdd);
        return;
      }
      clockPaused = true;
      final again = await ctx.requestContinue();
      clockPaused = false;
      if (!mounted) return;
      if (again) {
        setState(game.bonusAdd);
      } else {
        _end(_chain && _solved > 0);
      }
    }
  }

  void _end(bool won) {
    if (_ended) return;
    _ended = true;
    stopClock();
    final stars = _chain ? (_solved >= 4 ? 3 : _solved >= 2 ? 2 : 1) : MatchRules.stars(game);
    ctx.finish(RoundResult(
      won: won,
      score: _score,
      stars: won ? stars : 0,
      seconds: seconds,
      moves: game.moves,
      hintsUsed: _hints,
      undosUsed: _undos,
      gameStats: {
        'pairs_matched': _pairsTotal,
        'rows_cleared': _rowsTotal,
        'boards_cleared': won ? 1 + _solved : _solved,
      },
    ));
  }

  Future<void> _useHint() async {
    final p = game.findPair();
    if (p == null) {
      ctx.sfx(Sfx.error);
      return;
    }
    if (!await ctx.requestHint()) return;
    _hints++;
    setState(() => _hint = p);
  }

  void _add() {
    if (!game.addNumbers()) return;
    ctx.sfx(Sfx.place);
    setState(() {});
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final t = ctx.t;
    final colors = ctx.pieceColors;
    return Column(children: [
      PlayHud(items: [
        (Icons.star, '${t('score')}: $_score'),
        (Icons.grid_on, '${game.cells.where((c) => c != 0).length}'),
        (Icons.timer, timeText),
        if (_chain) (Icons.emoji_events, '$_solved'),
      ]),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final cell = ((c.maxWidth - 16) / kCols).clamp(24.0, 64.0);
          return Center(
            child: SizedBox(
              width: cell * kCols,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: kCols),
                itemCount: game.cells.length,
                itemBuilder: (_, i) {
                  final v = game.cells[i];
                  final sel = _sel == i;
                  final hinted = _hint?.contains(i) ?? false;
                  return Semantics(
                    button: v != 0,
                    label: v == 0 ? 'empty' : '$v',
                    child: GestureDetector(
                      onTap: () => _tap(i),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: ctx.reducedMotion ? 0 : 120),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: v == 0
                              ? Colors.white.withValues(alpha: 0.06)
                              : sel
                                  ? Colors.amber
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: hinted ? Border.all(color: Colors.yellowAccent, width: 3) : null,
                        ),
                        alignment: Alignment.center,
                        child: v == 0
                            ? null
                            : Text(
                                '$v',
                                style: TextStyle(
                                  fontSize: cell * 0.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color.lerp(colors[v % colors.length], Colors.black, 0.35),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
      BoosterBar(buttons: [
        BoosterButton(Icons.lightbulb, t('hint'), _useHint),
        BoosterButton(Icons.undo, t('undo'), game.canUndo
            ? () {
                setState(() {
                  game.undo();
                  _undos++;
                });
                _persist();
              }
            : null),
        BoosterButton(Icons.playlist_add, '+ (${game.addsLeft})', game.addsLeft > 0 ? _add : null),
      ]),
    ]);
  }
}
