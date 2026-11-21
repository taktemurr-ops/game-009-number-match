import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

const int kCols = 9;

class MatchLevel {
  final List<int> start; // digits 1..9 in reading order
  final int adds; // "add numbers" uses
  final int timeLimit;
  final int difficulty;
  final int seed;

  const MatchLevel({
    required this.start,
    required this.adds,
    required this.timeLimit,
    required this.difficulty,
    required this.seed,
  });
}

bool digitsMatch(int a, int b) => a > 0 && b > 0 && (a == b || a + b == 10);

class MatchGame {
  final MatchLevel level;
  late List<int> cells; // 0 = cleared
  late int addsLeft;
  int score = 0;
  int matches = 0;
  int rowsCleared = 0;
  int moves = 0;
  final List<String> _undo = [];

  MatchGame(this.level) {
    cells = List.of(level.start);
    addsLeft = level.adds;
  }

  int get rows => (cells.length + kCols - 1) ~/ kCols;
  int at(int x, int y) {
    final i = y * kCols + x;
    return i < cells.length ? cells[i] : -1;
  }

  bool get won => cells.every((c) => c == 0);

  /// True if a and b may be matched (connection rules only, not values).
  bool connected(int a, int b) {
    if (a == b) return false;
    final lo = a < b ? a : b, hi = a < b ? b : a;
    // Reading order (wraps rows).
    var clear = true;
    for (var i = lo + 1; i < hi; i++) {
      if (cells[i] != 0) {
        clear = false;
        break;
      }
    }
    if (clear) return true;
    final ax = a % kCols, ay = a ~/ kCols, bx = b % kCols, by = b ~/ kCols;
    final dx = (bx - ax).sign, dy = (by - ay).sign;
    final straight = ax == bx || ay == by || (bx - ax).abs() == (by - ay).abs();
    if (!straight) return false;
    var x = ax + dx, y = ay + dy;
    while (x != bx || y != by) {
      if (at(x, y) != 0) return false;
      x += dx;
      y += dy;
    }
    return true;
  }

  bool canMatch(int a, int b) =>
      a >= 0 && b >= 0 && a < cells.length && b < cells.length && digitsMatch(cells[a], cells[b]) && connected(a, b);

  /// Removes the pair; clears empty rows. Returns rows removed.
  int match(int a, int b) {
    if (!canMatch(a, b)) return -1;
    _push();
    cells[a] = 0;
    cells[b] = 0;
    matches++;
    moves++;
    score += 10;
    var removed = 0;
    for (var r = rows - 1; r >= 0; r--) {
      final s = r * kCols, e = (s + kCols).clamp(0, cells.length);
      if (e - s == kCols && cells.sublist(s, e).every((c) => c == 0)) {
        cells.removeRange(s, e);
        removed++;
      }
    }
    // Trailing cleared cells on the last row can go too.
    while (cells.isNotEmpty && cells.last == 0 && cells.length % kCols != 0) {
      cells.removeLast();
    }
    if (cells.every((c) => c == 0)) cells.clear();
    rowsCleared += removed;
    score += removed * 50;
    return removed;
  }

  /// "Add numbers": copies the remaining digits to the end.
  bool addNumbers() {
    if (addsLeft <= 0) return false;
    _push();
    final rest = cells.where((c) => c != 0).toList();
    cells.addAll(rest);
    addsLeft--;
    moves++;
    return true;
  }

  List<int>? findPair() {
    for (var a = 0; a < cells.length; a++) {
      if (cells[a] == 0) continue;
      for (var b = a + 1; b < cells.length; b++) {
        if (canMatch(a, b)) return [a, b];
      }
    }
    return null;
  }

  bool get stuck => !won && findPair() == null && addsLeft <= 0;

  void bonusAdd() => addsLeft++;

  void _push() {
    _undo.add(_snap());
    if (_undo.length > 60) _undo.removeAt(0);
  }

  bool get canUndo => _undo.isNotEmpty;
  void undo() {
    if (_undo.isNotEmpty) _restore(_undo.removeLast());
  }

  String _snap() => '${cells.join()}#$addsLeft#$score#$matches#$rowsCleared#$moves';
  void _restore(String s) {
    final p = s.split('#');
    cells = p[0].isEmpty ? <int>[] : p[0].split('').map(int.parse).toList();
    addsLeft = int.parse(p[1]);
    score = int.parse(p[2]);
    matches = int.parse(p[3]);
    rowsCleared = int.parse(p[4]);
    moves = int.parse(p[5]);
  }

  String serialize() => _snap();
  static MatchGame restore(MatchLevel l, String s) => MatchGame(l).._restore(s);
}

/// Constructive generator: pairs are inserted as neighbours in reading
/// order, so removing them in reverse insertion order always clears the
/// board -> every level is solvable without "add numbers".
MatchLevel generateMatch(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  var pairs = 12 + d * 3;
  if (spec.has('big')) pairs += 9;
  final seq = <int>[];
  for (var k = 0; k < pairs; k++) {
    final a = 1 + r.nextInt(9);
    final b = r.chance(0.5) ? a : 10 - a;
    final p = r.nextInt(seq.length + 1);
    seq.insertAll(p, r.chance(0.5) ? [a, b] : [b, a]);
  }
  return MatchLevel(
    start: seq,
    adds: spec.has('limited_adds') ? 2 : 5,
    timeLimit: spec.mode == GameModeId.timeAttack ? 120 : (spec.has('timer') ? 60 + pairs * 6 : 0),
    difficulty: d,
    seed: spec.seed,
  );
}

/// Solver used for validation: depth-first over matches with memo.
bool solvableMatch(MatchLevel l, {int budget = 20000}) {
  final seen = <String>{};
  var nodes = 0;
  bool dfs(MatchGame g) {
    if (g.won) return true;
    if (++nodes > budget) return false;
    if (!seen.add(g.cells.join())) return false;
    // Prefer reading-order neighbours (the constructive solution).
    final pairs = <List<int>>[];
    for (var a = 0; a < g.cells.length; a++) {
      if (g.cells[a] == 0) continue;
      var b = a + 1;
      while (b < g.cells.length && g.cells[b] == 0) {
        b++;
      }
      if (b < g.cells.length && digitsMatch(g.cells[a], g.cells[b])) pairs.add([a, b]);
    }
    for (final p in pairs) {
      final c = MatchGame(l)
        ..cells = List.of(g.cells)
        ..addsLeft = 0;
      c.match(p[0], p[1]);
      if (dfs(c)) return true;
    }
    return false;
  }

  return dfs(MatchGame(l)..addsLeft = 0);
}
