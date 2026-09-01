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
  final String variantId;
  final String baseId;
  final String label;
  final List<String> alphabet;
  final List<Difficulty> difficulties;
  final UiStrings ui;

  const Language({
    required this.id,
    required this.variantId,
    required this.baseId,
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
  subtitle: 'Português (PT)',
  homeHint: 'Escolhe um nível de dificuldade para começar a resolver o puzzle.',
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

const UiStrings _ptBrUi = UiStrings(
  appTitle: 'Palavras Cruzadas',
  subtitle: 'Português (BR)',
  homeHint: 'Escolha um nível de dificuldade para começar.',
  clues: 'Pistas',
  newPuzzle: 'Novo puzzle',
  tapToStart: 'Toque numa casa para começar',
  hint: 'Dica',
  clear: 'Limpar',
  check: 'Verificar',
  across: 'Horizontais',
  down: 'Verticais',
  solvedTitle: 'Parabéns!',
  statusTitle: 'Status do puzzle',
  solvedBody: 'Você resolveu o puzzle por completo!',
  lettersWord: 'letras',
  close: 'Fechar',
);

const UiStrings _esUi = UiStrings(
  appTitle: 'Crucigramas',
  subtitle: 'Español (ES)',
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

const UiStrings _es419Ui = UiStrings(
  appTitle: 'Crucigramas',
  subtitle: 'Español (LatAm)',
  homeHint: 'Elige un nivel de dificultad para empezar.',
  clues: 'Pistas',
  newPuzzle: 'Nuevo puzzle',
  tapToStart: 'Toca una casilla para empezar',
  hint: 'Pista',
  clear: 'Borrar',
  check: 'Verificar',
  across: 'Horizontales',
  down: 'Verticales',
  solvedTitle: '¡Felicidades!',
  statusTitle: 'Estado del puzzle',
  solvedBody: '¡Has completado el puzzle por completo!',
  lettersWord: 'letras',
  close: 'Cerrar',
);

const UiStrings _enUsUi = UiStrings(
  appTitle: 'Crossword',
  subtitle: 'English (US)',
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

const UiStrings _enGbUi = UiStrings(
  appTitle: 'Crossword',
  subtitle: 'English (UK)',
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

class LocaleVariant {
  final String variantId;
  final String baseId;
  final String label;
  final List<String> alphabet;
  final UiStrings ui;
  final String assetBase;
  final String? assetOverlay;

  const LocaleVariant({
    required this.variantId,
    required this.baseId,
    required this.label,
    required this.alphabet,
    required this.ui,
    required this.assetBase,
    this.assetOverlay,
  });
}

const List<LocaleVariant> localeVariants = [
  LocaleVariant(variantId: 'pt-PT', baseId: 'pt', label: 'Português (PT)', alphabet: _azList, ui: _ptUi, assetBase: 'pt', assetOverlay: 'pt-PT'),
  LocaleVariant(variantId: 'pt-BR', baseId: 'pt', label: 'Português (BR)', alphabet: _azList, ui: _ptBrUi, assetBase: 'pt', assetOverlay: 'pt-BR'),
  LocaleVariant(variantId: 'es-ES', baseId: 'es', label: 'Español (ES)', alphabet: _azNList, ui: _esUi, assetBase: 'es', assetOverlay: 'es-ES'),
  LocaleVariant(variantId: 'es-419', baseId: 'es', label: 'Español (LatAm)', alphabet: _azNList, ui: _es419Ui, assetBase: 'es', assetOverlay: 'es-419'),
  LocaleVariant(variantId: 'en-US', baseId: 'en', label: 'English (US)', alphabet: _azList, ui: _enUsUi, assetBase: 'en', assetOverlay: 'en-US'),
  LocaleVariant(variantId: 'en-GB', baseId: 'en', label: 'English (UK)', alphabet: _azList, ui: _enGbUi, assetBase: 'en', assetOverlay: 'en-GB'),
];

const Map<String, String> _variantFallback = {
  'pt': 'pt-PT',
  'es': 'es-ES',
  'en': 'en-US',
  'pt-PT': 'pt-PT',
  'pt-BR': 'pt-BR',
  'es-ES': 'es-ES',
  'es-419': 'es-419',
  'en-US': 'en-US',
  'en-GB': 'en-GB',
};

String resolveVariantId(String raw) {
  final lower = raw.toLowerCase();
  if (_variantFallback.containsKey(lower)) return _variantFallback[lower]!;
  if (lower.startsWith('pt')) return 'pt-PT';
  if (lower.startsWith('es')) return 'es-ES';
  if (lower.startsWith('en-gb') || lower == 'en-uk') return 'en-GB';
  if (lower.startsWith('en')) return 'en-US';
  return 'pt-PT';
}

LocaleVariant variantFor(String variantId) =>
    localeVariants.firstWhere((v) => v.variantId == variantId, orElse: () => localeVariants.first);

Future<List<Language>> loadLanguages() async {
  final List<Language> result = [];
  for (final v in localeVariants) {
    final difficulties = await loadLevelsForVariant(v.variantId);
    result.add(Language(
      id: v.variantId,
      variantId: v.variantId,
      baseId: v.baseId,
      label: v.label,
      alphabet: v.alphabet,
      difficulties: difficulties,
      ui: v.ui,
    ));
  }
  return result;
}

Future<List<Language>> loadLanguagesForIds(List<String> ids) async {
  final List<Language> result = [];
  for (final id in ids) {
    final v = variantFor(resolveVariantId(id));
    final difficulties = await loadLevelsForVariant(v.variantId);
    result.add(Language(
      id: v.variantId,
      variantId: v.variantId,
      baseId: v.baseId,
      label: v.label,
      alphabet: v.alphabet,
      difficulties: difficulties,
      ui: v.ui,
    ));
  }
  return result;
}

String _dailyName(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

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

Difficulty buildDailyDifficulty(Language lang, DateTime date) => Difficulty(
      id: 'diario',
      label: 'Puzzle Diário',
      description: 'Um desafio novo todos os dias',
      levels: [buildDailyLevel(lang, date)],
    );
