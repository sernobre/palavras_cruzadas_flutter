class Entry {
  final String word;
  final String clue;

  const Entry(this.word, this.clue);
}

class Level {
  final String name;
  final List<Entry> entries;

  const Level({required this.name, required this.entries});
}

class Difficulty {
  final String id;
  final String label;
  final String description;
  final List<Level> levels;

  const Difficulty({
    required this.id,
    required this.label,
    required this.description,
    required this.levels,
  });
}

class CellRef {
  int r;
  int c;

  CellRef(this.r, this.c);

  String get key => '$r,$c';

  @override
  bool operator ==(Object other) =>
      other is CellRef && other.r == r && other.c == c;

  @override
  int get hashCode => r * 1000 + c;
}

class Clue {
  final int number;
  final String text;
  final String answer;
  final List<CellRef> cells;
  final bool across;

  const Clue({
    required this.number,
    required this.text,
    required this.answer,
    required this.cells,
    required this.across,
  });
}

class CrosswordPuzzle {
  final int width;
  final int height;
  final Set<String> blocked;
  final Map<String, String> solution;
  final List<Clue> acrossClues;
  final List<Clue> downClues;

  const CrosswordPuzzle({
    required this.width,
    required this.height,
    required this.blocked,
    required this.solution,
    required this.acrossClues,
    required this.downClues,
  });

  bool isBlocked(int r, int c) => blocked.contains('$r,$c');
}
