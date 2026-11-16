import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const NumberMatchApp());

class NumberMatchBoard {
  NumberMatchBoard(List<int> numbers) : cells = List<int?>.from(numbers);

  final List<int?> cells;
  int score = 0;
  int matches = 0;

  bool get completed => cells.every((cell) => cell == null);
  int get remaining => cells.whereType<int>().length;

  bool isPair(int a, int b) {
    if (a == b || a < 0 || b < 0 || a >= cells.length || b >= cells.length) {
      return false;
    }
    final first = cells[a];
    final second = cells[b];
    if (first == null || second == null) return false;
    if (first != second && first + second != 10) return false;
    final low = min(a, b);
    final high = max(a, b);
    for (var i = low + 1; i < high; i++) {
      if (cells[i] != null) return false;
    }
    return true;
  }

  bool match(int a, int b) {
    if (!isPair(a, b)) return false;
    cells[a] = null;
    cells[b] = null;
    score += 10;
    matches++;
    return true;
  }

  void appendRemaining() {
    final remainingNumbers = cells.whereType<int>().toList();
    if (remainingNumbers.isNotEmpty && cells.length + remainingNumbers.length <= 144) {
      cells.addAll(remainingNumbers);
    }
  }
}

NumberMatchBoard createBoard(int level) {
  final random = Random(level + 100);
  final values = <int>[];
  for (var i = 0; i < 12; i++) {
    final value = random.nextInt(9) + 1;
    values.add(value);
    values.add(i.isEven ? value : 10 - value);
  }
  return NumberMatchBoard(values);
}

class NumberMatchApp extends StatelessWidget {
  const NumberMatchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Number Match',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
        home: const NumberMatchScreen(),
      );
}

class NumberMatchScreen extends StatefulWidget {
  const NumberMatchScreen({super.key});

  @override
  State<NumberMatchScreen> createState() => _NumberMatchScreenState();
}

class _NumberMatchScreenState extends State<NumberMatchScreen> {
  int level = 0;
  late NumberMatchBoard board = createBoard(level);
  int? selected;

  void tapCell(int index) {
    setState(() {
      if (selected == null) {
        selected = index;
      } else if (selected == index) {
        selected = null;
      } else {
        final previous = selected!;
        if (board.match(previous, index)) {
          selected = null;
        } else {
          selected = index;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Number Match')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('Level ${level + 1}  •  Score ${board.score}  •  Left ${board.remaining}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Match equal numbers or numbers adding to 10. Only pairs with no active numbers between them can match.'),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: board.cells.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemBuilder: (context, index) {
                      final value = board.cells[index];
                      return Semantics(
                        button: value != null,
                        label: 'Cell ${index + 1}: ${value ?? 'empty'}',
                        child: InkWell(
                          key: ValueKey('cell-$index'),
                          onTap: value == null ? null : () => tapCell(index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: value == null
                                  ? Colors.grey.shade100
                                  : selected == index
                                      ? Colors.deepPurple.shade200
                                      : Colors.deepPurple.shade50,
                              border: Border.all(color: Colors.deepPurple.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(value?.toString() ?? '',
                                style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (board.completed)
                  const Text('Board cleared! Well done.', key: ValueKey('completed')),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                  OutlinedButton(
                    onPressed: board.completed ? null : () => setState(() {
                      board.appendRemaining();
                      selected = null;
                    }),
                    child: const Text('Add numbers'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      board = createBoard(level);
                      selected = null;
                    }),
                    child: const Text('Restart'),
                  ),
                  FilledButton(
                    onPressed: () => setState(() {
                      level++;
                      board = createBoard(level);
                      selected = null;
                    }),
                    child: const Text('Next level'),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
