import 'package:flutter_test/flutter_test.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/models/generator.dart';
import 'package:palavrascruzadas/services/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generator produces valid, conflict-free puzzles for every language',
      () async {
    final languages = await loadLanguages();
    for (final lang in languages) {
      final allEntries = lang.difficulties
          .expand((d) => d.levels)
          .expand((l) => l.entries)
          .toList();
      final puzzle = generateCrossword(
        allEntries,
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

  test('spanish alphabet keeps Ñ', () async {
    final languages = await loadLanguages();
    final es = languages.firstWhere((l) => l.variantId == 'es-ES');
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
    expect(normalizeWord('Coração', {'A', 'B', 'C', 'O', 'R'}),
        equals('CORACAO'));
    expect(normalizeWord('AÑO', {'A', 'N', 'O', 'Ñ'}), equals('AÑO'));
    expect(normalizeWord('Órgão', {'A', 'G', 'O', 'R'}), equals('ORGAO'));
  });

  test('daily level is deterministic and non-empty for a date', () async {
    final languages = await loadLanguages();
    final lang = languages.first;
    final d1 = buildDailyLevel(lang, DateTime(2026, 8, 26));
    final d2 = buildDailyLevel(lang, DateTime(2026, 8, 26));
    final d3 = buildDailyLevel(lang, DateTime(2026, 8, 27));
    expect(d1.entries.length, greaterThan(0));
    expect(d1.entries.map((e) => e.word), equals(d2.entries.map((e) => e.word)));
    expect(d1.entries.map((e) => e.word),
        isNot(equals(d3.entries.map((e) => e.word))));
  });

  test('streak increments on consecutive days and resets on gap', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final d1 = DateTime(2026, 8, 26);
    final d2 = DateTime(2026, 8, 27);
    final d4 = DateTime(2026, 8, 29);

    await store.recordDaily('pt', d1);
    expect(store.streak, 1);
    await store.recordDaily('pt', d2);
    expect(store.streak, 2);
    expect(store.dailyCompletedToday('pt', d2), isTrue);
    expect(store.dailyCompletedToday('pt', d1), isTrue);

    // gap of one day resets the streak to 1
    await store.recordDaily('pt', d4);
    expect(store.streak, 1);
  });
}
