import 'package:flutter_test/flutter_test.dart';
import 'package:game_009_number_match/main.dart';

void main() {
  group('NumberMatchBoard', () {
    test('matches adjacent equal numbers and awards points once', () {
      final board = NumberMatchBoard([4, 4, 2]);
      expect(board.match(0, 1), isTrue);
      expect(board.score, 10);
      expect(board.matches, 1);
      expect(board.match(0, 1), isFalse);
      expect(board.score, 10);
    });

    test('rejects nonadjacent occupied pairs and invalid indices', () {
      final board = NumberMatchBoard([5, 2, 5]);
      expect(board.isPair(0, 2), isFalse);
      expect(board.isPair(-1, 1), isFalse);
      expect(board.isPair(0, 3), isFalse);
      expect(board.isPair(0, 0), isFalse);
    });

    test('free hint finds valid pair without changing score or cells', () {
      final board = NumberMatchBoard([3, 7, 4]);
      expect(board.findHint(), [0, 1]);
      expect(board.score, 0);
      expect(board.remaining, 3);
      expect(board.cells, [3, 7, 4]);
    });

    test('hint skips blocked pairs and reports no move', () {
      final board = NumberMatchBoard([4, 2, 4]);
      expect(board.findHint(), isNull);
    });

    test('appendRemaining retains board and respects size limit', () {
      final board = NumberMatchBoard([1, 9]);
      board.appendRemaining();
      expect(board.cells, [1, 9, 1, 9]);
      final full = NumberMatchBoard(List.filled(100, 1));
      full.appendRemaining();
      expect(full.cells.length, 100);
    });

    test('cleared board is completed', () {
      final board = NumberMatchBoard([5, 5]);
      expect(board.match(0, 1), isTrue);
      expect(board.completed, isTrue);
      expect(board.findHint(), isNull);
    });
  });
}
