import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_009_number_match/main.dart';

void main() {
  test('matching equal numbers removes them and scores points', () {
    final board = NumberMatchBoard([3, 3, 2, 8]);
    expect(board.match(0, 1), isTrue);
    expect(board.score, 10);
    expect(board.match(2, 3), isTrue);
    expect(board.completed, isTrue);
  });

  test('non-adjacent pairs require cleared spaces', () {
    final board = NumberMatchBoard([4, 5, 6, 4]);
    expect(board.match(0, 3), isFalse);
    expect(board.match(1, 2), isFalse);
    final other = NumberMatchBoard([4, 6, 6, 4]);
    expect(other.match(1, 2), isTrue);
    expect(other.match(0, 3), isTrue);
  });

  test('append adds remaining numbers without changing score', () {
    final board = NumberMatchBoard([1, 1, 7, 3]);
    expect(board.match(0, 1), isTrue);
    board.appendRemaining();
    expect(board.cells.length, 6);
    expect(board.score, 10);
  });

  testWidgets('renders a playable number grid', (tester) async {
    await tester.pumpWidget(const NumberMatchApp());
    expect(find.byKey(const ValueKey('cell-0')), findsOneWidget);
    expect(find.text('Add numbers'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
  });
}
