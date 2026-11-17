import 'package:flutter_test/flutter_test.dart';
import 'package:game_009_number_match/main.dart';

void main() {
  test('equal and ten-sum adjacent pairs score once', () {
    final board = NumberMatchBoard([3, 3, 4, 6]);
    expect(board.isPair(0, 1), isTrue);
    expect(board.match(0, 1), isTrue);
    expect(board.match(0, 1), isFalse);
    expect(board.match(2, 3), isTrue);
    expect(board.completed, isTrue);
    expect(board.score, 20);
    expect(board.matches, 2);
  });

  test('nonempty intermediate cell blocks a pair', () {
    final board = NumberMatchBoard([5, 2, 5]);
    expect(board.isPair(0, 2), isFalse);
    expect(board.findHint(), isNull);
    expect(board.isPair(-1, 0), isFalse);
    expect(board.isPair(0, 3), isFalse);
  });

  test('append remaining respects the 144 cell cap', () {
    final board = NumberMatchBoard([1, 9]);
    board.appendRemaining();
    expect(board.cells, [1, 9, 1, 9]);
    final full = NumberMatchBoard(List.filled(100, 1));
    full.appendRemaining();
    expect(full.cells.length, 100);
  });

  test('generated boards are reproducible per level', () {
    expect(createBoard(4).cells, createBoard(4).cells);
  });
}
