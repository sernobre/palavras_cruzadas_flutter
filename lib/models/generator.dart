import 'crossword.dart';

const Map<String, String> _diacritics = {
  'Á': 'A',
  'Â': 'A',
  'Ã': 'A',
  'À': 'A',
  'Ä': 'A',
  'É': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Í': 'I',
  'Ï': 'I',
  'Ó': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ö': 'O',
  'Ú': 'U',
  'Ü': 'U',
  'Ç': 'C',
  'Ñ': 'Ñ',
};

Set<String> alphabetAZ() => {
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    };

String stripDiacritics(String s) => normalizeWord(s, alphabetAZ());

String normalizeWord(String s, Set<String> alphabet) {
  s = s.toUpperCase();
  final buffer = StringBuffer();
  for (final ch in s.runes) {
    final c = String.fromCharCode(ch);
    final mapped = _diacritics[c] ?? c;
    if (alphabet.contains(mapped)) buffer.write(mapped);
  }
  return buffer.toString();
}

class _Placed {
  final Entry entry;
  final String word;
  int startRow;
  int startCol;
  final bool across;
  final List<CellRef> cells = [];
  int number = 0;

  _Placed(this.entry, this.word, this.startRow, this.startCol, this.across);
}

String _k(int r, int c) => '$r,$c';

class _StartEntry {
  final int r;
  final int c;
  final _Placed pe;

  _StartEntry(this.r, this.c, this.pe);
}

CrosswordPuzzle generateCrossword(List<Entry> entries,
    {Set<String>? alphabet}) {
  final alpha = alphabet ?? alphabetAZ();
  final usable = entries
      .where((e) => normalizeWord(e.word, alpha).length >= 2)
      .toList();
  final sorted = [...usable]
    ..sort((a, b) => normalizeWord(b.word, alpha).length
        .compareTo(normalizeWord(a.word, alpha).length));

  final placed = <_Placed>[];
  final occ = <String, String>{};

  bool canPlace(String w, int r0, int c0, bool across) {
    final len = w.length;
    if (across) {
      if (occ.containsKey(_k(r0, c0 - 1))) return false;
      if (occ.containsKey(_k(r0, c0 + len))) return false;
      for (var k = 0; k < len; k++) {
        final r = r0;
        final c = c0 + k;
        final key = _k(r, c);
        if (occ.containsKey(key)) {
          if (occ[key] != w[k]) return false;
        } else {
          if (occ.containsKey(_k(r - 1, c))) return false;
          if (occ.containsKey(_k(r + 1, c))) return false;
        }
      }
    } else {
      if (occ.containsKey(_k(r0 - 1, c0))) return false;
      if (occ.containsKey(_k(r0 + len, c0))) return false;
      for (var k = 0; k < len; k++) {
        final r = r0 + k;
        final c = c0;
        final key = _k(r, c);
        if (occ.containsKey(key)) {
          if (occ[key] != w[k]) return false;
        } else {
          if (occ.containsKey(_k(r, c - 1))) return false;
          if (occ.containsKey(_k(r, c + 1))) return false;
        }
      }
    }
    return true;
  }

  void doPlace(String w, int r0, int c0, bool across, Entry e) {
    final pe = _Placed(e, w, r0, c0, across);
    for (var k = 0; k < w.length; k++) {
      final r = across ? r0 : r0 + k;
      final c = across ? c0 + k : c0;
      occ[_k(r, c)] = w[k];
      pe.cells.add(CellRef(r, c));
    }
    placed.add(pe);
  }

  if (sorted.isEmpty) {
    return CrosswordPuzzle(
      width: 1,
      height: 1,
      blocked: {'0,0'},
      solution: const {},
      acrossClues: const [],
      downClues: const [],
    );
  }

  final first = sorted.first;
  final firstWord = normalizeWord(first.word, alpha);
  doPlace(firstWord, 0, 0, true, first);

  for (var i = 1; i < sorted.length; i++) {
    final e = sorted[i];
    final w = normalizeWord(e.word, alpha);
    outer:
    for (final pe in placed) {
      for (var pi = 0; pi < pe.cells.length; pi++) {
        final cell = pe.cells[pi];
        final letter = pe.word[pi];
        for (var wi = 0; wi < w.length; wi++) {
          if (w[wi] == letter) {
            final r0 = pe.across ? cell.r - wi : cell.r;
            final c0 = pe.across ? cell.c : cell.c - wi;
            final newAcross = !pe.across;
            if (canPlace(w, r0, c0, newAcross)) {
              doPlace(w, r0, c0, newAcross, e);
              break outer;
            }
          }
        }
      }
    }
  }

  var minR = 0;
  var maxR = 0;
  var minC = 0;
  var maxC = 0;
  for (final pe in placed) {
    for (final cell in pe.cells) {
      if (cell.r < minR) minR = cell.r;
      if (cell.r > maxR) maxR = cell.r;
      if (cell.c < minC) minC = cell.c;
      if (cell.c > maxC) maxC = cell.c;
    }
  }

  for (final pe in placed) {
    pe.startRow -= minR;
    pe.startCol -= minC;
    for (final cell in pe.cells) {
      cell.r -= minR;
      cell.c -= minC;
    }
  }

  final width = maxC - minC + 1;
  final height = maxR - minR + 1;

  final starts = <_StartEntry>[];
  for (final pe in placed) {
    starts.add(_StartEntry(pe.startRow, pe.startCol, pe));
  }
  starts.sort((a, b) {
    if (a.r != b.r) return a.r.compareTo(b.r);
    return a.c.compareTo(b.c);
  });

  var num = 0;
  String? lastKey;
  for (final s in starts) {
    final key = '${s.r},${s.c}';
    if (key != lastKey) {
      num++;
      lastKey = key;
    }
    s.pe.number = num;
  }

  final acrossClues = <Clue>[];
  final downClues = <Clue>[];
  final solution = <String, String>{};
  final blocked = <String>{};

  occ.forEach((key, letter) {
    final parts = key.split(',');
    final r = int.parse(parts[0]) - minR;
    final c = int.parse(parts[1]) - minC;
    solution['$r,$c'] = letter;
  });

  for (var r = 0; r < height; r++) {
    for (var c = 0; c < width; c++) {
      if (!solution.containsKey('$r,$c')) {
        blocked.add('$r,$c');
      }
    }
  }

  for (final pe in placed) {
    final clue = Clue(
      number: pe.number,
      text: pe.entry.clue,
      answer: pe.word,
      cells: pe.cells,
      across: pe.across,
    );
    if (pe.across) {
      acrossClues.add(clue);
    } else {
      downClues.add(clue);
    }
  }

  acrossClues.sort((a, b) => a.number.compareTo(b.number));
  downClues.sort((a, b) => a.number.compareTo(b.number));

  return CrosswordPuzzle(
    width: width,
    height: height,
    blocked: blocked,
    solution: solution,
    acrossClues: acrossClues,
    downClues: downClues,
  );
}
