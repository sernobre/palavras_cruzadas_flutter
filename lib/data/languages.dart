import 'dart:math';

import '../models/crossword.dart';
import 'level_loader.dart';

class UiStrings {
  final String appTitle;
  final String subtitle;
  final String homeHint;
  final String clues;
  final String newPuzzle;
  final String tapToStart;
  final String hint;
  final String clear;
  final String check;
  final String across;
  final String down;
  final String solvedTitle;
  final String statusTitle;
  final String solvedBody;
  final String close;
  final String lettersWord;

  const UiStrings({
    required this.appTitle,
    required this.subtitle,
    required this.homeHint,
    required this.clues,
    required this.newPuzzle,
    required this.tapToStart,
    required this.hint,
    required this.clear,
    required this.check,
    required this.across,
    required this.down,
    required this.solvedTitle,
    required this.statusTitle,
    required this.solvedBody,
    required this.close,
    required this.lettersWord,
  });

  String progress(int correct, int total) => '$correct/$total';
  String statusBody(int correct, int total) => '$correct/$total';
}

class Language {
  final String id;
  final String label;
  final List<String> alphabet;
  final List<Difficulty> difficulties;
  final UiStrings ui;

  const Language({
    required this.id,
    required this.label,
    required this.alphabet,
    required this.difficulties,
    required this.ui,
  });

  Difficulty difficultyById(String id) =>
      difficulties.firstWhere((d) => d.id == id);
}

const List<String> _azList = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

const List<String> _azNList = [..._azList, 'Ñ'];

const UiStrings _ptUi = UiStrings(
  appTitle: 'Palavras Cruzadas',
  subtitle: 'Português',
  homeHint:
      'Escolhe um nível de dificuldade para começar a resolver o puzzle.',
  clues: 'Pistas',
  newPuzzle: 'Novo puzzle',
  tapToStart: 'Toca numa casa para começar',
  hint: 'Dica',
  clear: 'Limpar',
  check: 'Verificar',
  across: 'Horizontais',
  down: 'Verticais',
  solvedTitle: 'Parabéns!',
  statusTitle: 'Estado do puzzle',
  solvedBody: 'Resolveste o puzzle por completo. Muito bem!',
  lettersWord: 'letras',
  close: 'Fechar',
);

const UiStrings _esUi = UiStrings(
  appTitle: 'Crucigramas',
  subtitle: 'Español',
  homeHint: 'Elige un nivel de dificultad para empezar a resolver el puzzle.',
  clues: 'Pistas',
  newPuzzle: 'Nuevo puzzle',
  tapToStart: 'Toca una casilla para empezar',
  hint: 'Pista',
  clear: 'Borrar',
  check: 'Verificar',
  across: 'Horizontales',
  down: 'Verticales',
  solvedTitle: '¡Enhorabuena!',
  statusTitle: 'Estado del puzzle',
  solvedBody: 'Has resuelto el puzzle por completo. ¡Muy bien!',
  lettersWord: 'letras',
  close: 'Cerrar',
);

const UiStrings _enUi = UiStrings(
  appTitle: 'Crossword',
  subtitle: 'English',
  homeHint: 'Choose a difficulty level to start solving the puzzle.',
  clues: 'Clues',
  newPuzzle: 'New puzzle',
  tapToStart: 'Tap a cell to start',
  hint: 'Hint',
  clear: 'Clear',
  check: 'Check',
  across: 'Across',
  down: 'Down',
  solvedTitle: 'Congratulations!',
  statusTitle: 'Puzzle status',
  solvedBody: 'You solved the whole puzzle. Well done!',
  lettersWord: 'letters',
  close: 'Close',
);

class _LanguageDef {
  final String id;
  final String label;
  final List<String> alphabet;
  final UiStrings ui;

  const _LanguageDef(this.id, this.label, this.alphabet, this.ui);
}

const List<_LanguageDef> _defs = [
  _LanguageDef('pt', 'Português', _azList, _ptUi),
  _LanguageDef('es', 'Español', _azNList, _esUi),
  _LanguageDef('en', 'English', _azList, _enUi),
];

Future<List<Language>> loadLanguages() async {
  final List<Language> result = [];
  for (final def in _defs) {
    final difficulties = await loadLevelsFor(def.id);
    result.add(Language(
      id: def.id,
      label: def.label,
      alphabet: def.alphabet,
      difficulties: difficulties,
      ui: def.ui,
    ));
  }
  return result;
}

String _dailyName(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

/// Builds a deterministic daily puzzle from all words of [lang] for [date].
Level buildDailyLevel(Language lang, DateTime date, {int count = 9}) {
  final all = lang.difficulties
      .expand((d) => d.levels)
      .expand((l) => l.entries)
      .toList();

  final seen = <String>{};
  final unique = <Entry>[];
  for (final e in all) {
    final w = e.word.toUpperCase();
    if (seen.add(w)) unique.add(e);
  }

  final seed = date.year * 10000 + date.month * 100 + date.day;
  unique.shuffle(Random(seed));

  return Level(name: _dailyName(date), entries: unique.take(count).toList());
}

/// A synthetic difficulty holding only the daily puzzle for [date].
Difficulty buildDailyDifficulty(Language lang, DateTime date) => Difficulty(
      id: 'diario',
      label: 'Puzzle Diário',
      description: 'Um desafio novo todos os dias',
      levels: [buildDailyLevel(lang, date)],
    );
