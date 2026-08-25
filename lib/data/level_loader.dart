import 'package:flutter/services.dart' show rootBundle;

import '../models/crossword.dart';

/// Formato (um ficheiro por idioma), ex.:
///
/// # facil
/// label: Fácil
/// description: Palavras curtas do dia a dia
/// ## Nível 1
/// SOL: Astro que ilumina o dia
/// MAR: Grande extensão de água salgada
/// ## Nível 2
/// ...
/// # medio
/// ...
///
/// Regras:
/// - Linhas vazias ou que começam por `//` são ignoradas.
/// - `# id` inicia uma dificuldade (id em minúsculas: facil/medio/dificil).
/// - `label:` e `description:` (após `#`) definem o texto da dificuldade.
/// - `## Nome` inicia um nível.
/// - `PALAVRA: pista` adiciona uma entrada ao nível atual.
/// A normalização de acentos/caracteres é feita pelo gerador.

List<Difficulty> parseLevels(String text) {
  final difficulties = <Difficulty>[];
  Difficulty? current;
  Level? currentLevel;

  Difficulty newDifficulty(String id) => Difficulty(
        id: id,
        label: id,
        description: '',
        levels: [],
      );

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('//')) continue;

    if (line.startsWith('## ')) {
      final name = line.substring(3).trim();
      currentLevel = Level(name: name, entries: []);
      current?.levels.add(currentLevel);
      continue;
    }

    if (line.startsWith('# ')) {
      final id = line.substring(2).trim().toLowerCase();
      current = newDifficulty(id);
      difficulties.add(current);
      currentLevel = null;
      continue;
    }

    final colon = line.indexOf(':');
    if (colon <= 0 || current == null) continue;

    final key = line.substring(0, colon).trim();
    final value = line.substring(colon + 1).trim();

    if (currentLevel == null) {
      if (key.toLowerCase() == 'label') {
        current.label = value;
      } else if (key.toLowerCase() == 'description') {
        current.description = value;
      }
    } else {
      currentLevel.entries.add(Entry(key.toUpperCase(), value));
    }
  }

  return difficulties;
}

String serializeLevels(List<Difficulty> difficulties) {
  final buffer = StringBuffer();
  for (final d in difficulties) {
    buffer.writeln('# ${d.id}');
    buffer.writeln('label: ${d.label}');
    buffer.writeln('description: ${d.description}');
    for (final level in d.levels) {
      buffer.writeln('## ${level.name}');
      for (final entry in level.entries) {
        buffer.writeln('${entry.word}: ${entry.clue}');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}

Future<List<Difficulty>> loadLevelsFor(String langId) async {
  final text =
      await rootBundle.loadString('assets/levels/levels_$langId.txt');
  return parseLevels(text);
}
