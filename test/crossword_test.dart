import 'package:flutter_test/flutter_test.dart';
import 'package:palavrascruzadas/data/words.dart';
import 'package:palavrascruzadas/models/generator.dart';

void main() {
  test('generator produces valid, conflict-free puzzles', () {
    for (final d in difficulties) {
      final puzzle = generateCrossword(d.entries);

      expect(puzzle.height, greaterThan(0));
      expect(puzzle.solution.isNotEmpty, isTrue);

      // No solution cell is blocked.
      for (final key in puzzle.solution.keys) {
        expect(puzzle.blocked.contains(key), isFalse);
      }

      // Every clue cell must exist in the solution with the right letter.
      for (final clue in [...puzzle.acrossClues, ...puzzle.downClues]) {
        expect(clue.cells.isNotEmpty, isTrue);
        for (final cell in clue.cells) {
          expect(cell.r, greaterThanOrEqualTo(0));
          expect(cell.r, lessThan(puzzle.height));
          expect(cell.c, greaterThanOrEqualTo(0));
          expect(cell.c, lessThan(puzzle.width));
          final key = cell.key;
          final expected = clue.answer[clue.cells.indexOf(cell)];
          expect(puzzle.solution[key], equals(expected));
        }
      }

      // At least one across and one down clue (connected grid).
      expect(puzzle.acrossClues.isNotEmpty, isTrue);
      expect(puzzle.downClues.isNotEmpty, isTrue);
    }
  });

  test('stripDiacritics keeps only A-Z', () {
    expect(stripDiacritics('Coração'), equals('CORACAO'));
    expect(stripDiacritics('Órgão'), equals('ORGAO'));
    expect(stripDiacritics('Açúcar'), equals('ACUCAR'));
  });
}
