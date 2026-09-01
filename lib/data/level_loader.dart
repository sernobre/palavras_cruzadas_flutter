import 'package:flutter/services.dart' show rootBundle;

import '../models/crossword.dart';
import 'languages.dart' show variantFor;

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

List<Difficulty> mergeLevels(List<Difficulty> base, List<Difficulty> overlay) {
  if (overlay.isEmpty) return base;
  final byId = {for (final d in base) d.id: d};
  for (final od in overlay) {
    final existing = byId[od.id];
    if (existing == null) {
      base.add(Difficulty(id: od.id, label: od.label, description: od.description, levels: od.levels));
      byId[od.id] = base.last;
      continue;
    }
    if (od.label != od.id) existing.label = od.label;
    if (od.description.isNotEmpty) existing.description = od.description;
    final levelByName = {for (final l in existing.levels) l.name: l};
    for (final ol in od.levels) {
      final el = levelByName[ol.name];
      if (el == null) {
        existing.levels.add(ol);
        continue;
      }
      final entryByWord = {for (final e in el.entries) e.word.toUpperCase(): e};
      for (final oe in ol.entries) {
        final key = oe.word.toUpperCase();
        if (entryByWord.containsKey(key)) {
          final idx = el.entries.indexWhere((e) => e.word.toUpperCase() == key);
          if (idx >= 0) el.entries[idx] = oe;
        } else {
          el.entries.add(oe);
        }
      }
      for (final oe in ol.entries) {
        if (oe.word.startsWith('-')) {
          final toRemove = oe.word.substring(1).toUpperCase();
          el.entries.removeWhere((e) => e.word.toUpperCase() == toRemove);
        }
      }
    }
  }
  return base;
}

Future<List<Difficulty>> loadLevelsFor(String langId) async {
  final text = await rootBundle.loadString('assets/levels/levels_$langId.txt');
  return parseLevels(text);
}

Future<List<Difficulty>> loadLevelsForVariant(String variantId) async {
  final v = variantFor(variantId);
  final baseText = await rootBundle.loadString('assets/levels/levels_${v.assetBase}.txt');
  final base = parseLevels(baseText);
  if (v.assetOverlay == null) return base;
  try {
    final overlayText = await rootBundle.loadString('assets/levels/levels_${v.assetOverlay}.txt');
    final overlay = parseLevels(overlayText);
    return mergeLevels(base, overlay);
  } catch (_) {
    return base;
  }
}
