import 'package:flutter_test/flutter_test.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/models/generator.dart';

void main() {
  test('generator produces valid, conflict-free puzzles for every language', () {
    for (final lang in languages) {
      final puzzle = generateCrossword(
        lang.difficulties.expand((d) => d.entries).toList(),
        alphabet: lang.alphabet.toSet(),
      );

      expect(puzzle.height, greaterThan(0));
      expect(puzzle.solution.isNotEmpty, isTrue);

      for (final key in puzzle.solution.keys) {
        expect(puzzle.blocked.contains(key), isFalse);
        expect(lang.alphabet.contains(puzzle.solution[key]), isTrue);
      }

      for (final clue in [...puzzle.acrossClues, ...puzzle.downClues]) {
        expect(clue.cells.isNotEmpty, isTrue);
        for (final cell in clue.cells) {
          expect(cell.r, greaterThanOrEqualTo(0));
          expect(cell.r, lessThan(puzzle.height));
          expect(cell.c, greaterThanOrEqualTo(0));
          expect(cell.c, lessThan(puzzle.width));
          final expected = clue.answer[clue.cells.indexOf(cell)];
          expect(puzzle.solution[cell.key], equals(expected));
        }
      }

      expect(puzzle.acrossClues.isNotEmpty, isTrue);
      expect(puzzle.downClues.isNotEmpty, isTrue);
    }
  });

  test('spanish alphabet keeps Ñ', () {
    final es = languages.firstWhere((l) => l.id == 'es');
    expect(es.alphabet.contains('Ñ'), isTrue);
    expect(normalizeWord('AÑO', es.alphabet.toSet()), equals('AÑO'));
    final puzzle = generateCrossword(
      const [Entry('AÑO', 'x'), Entry('NIÑO', 'y'), Entry('SOL', 'z')],
      alphabet: es.alphabet.toSet(),
    );
    expect(puzzle.solution.values.any((l) => l == 'Ñ'), isTrue);
    expect(puzzle.acrossClues.isNotEmpty, isTrue);
    expect(puzzle.downClues.isNotEmpty, isTrue);
  });

  test('normalizeWord keeps only alphabet letters', () {
    expect(normalizeWord('Coração', {'A', 'B', 'C', 'O', 'R'}), equals('CORACAO'));
    expect(normalizeWord('AÑO', {'A', 'N', 'O', 'Ñ'}), equals('AÑO'));
    expect(normalizeWord('Órgão', {'A', 'G', 'O', 'R'}), equals('ORGAO'));
  });
}
