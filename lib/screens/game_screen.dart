import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/models/generator.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';
import 'package:palavrascruzadas/widgets/clue_panel.dart';
import 'package:palavrascruzadas/widgets/crossword_board.dart';
import 'package:palavrascruzadas/widgets/keyboard.dart';

class GameScreen extends StatefulWidget {
  final Language language;
  final Difficulty difficulty;

  const GameScreen(
      {super.key, required this.language, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late CrosswordPuzzle _puzzle;
  final Map<String, String> _userInput = {};
  final Set<String> _revealed = {};
  String? _activeKey;
  bool _activeAcross = true;

  late Map<String, Clue> _cellAcross;
  late Map<String, Clue> _cellDown;
  late Map<String, int> _cellNumber;

  UiStrings get ui => widget.language.ui;

  @override
  void initState() {
    super.initState();
    _buildPuzzle();
  }

  void _buildPuzzle() {
    final entries = [...widget.difficulty.entries];
    entries.shuffle();
    _puzzle = generateCrossword(entries,
        alphabet: widget.language.alphabet.toSet());
    _userInput.clear();
    _revealed.clear();
    _cellAcross = {};
    _cellDown = {};
    _cellNumber = {};
    for (final clue in _puzzle.acrossClues) {
      for (final cell in clue.cells) {
        _cellAcross[cell.key] = clue;
      }
      _cellNumber[clue.cells.first.key] = clue.number;
    }
    for (final clue in _puzzle.downClues) {
      for (final cell in clue.cells) {
        _cellDown[cell.key] = clue;
      }
      _cellNumber[clue.cells.first.key] = clue.number;
    }
    _activeKey = _puzzle.acrossClues.isNotEmpty
        ? _puzzle.acrossClues.first.cells.first.key
        : null;
    _activeAcross = true;
  }

  Clue? get _activeClue {
    if (_activeKey == null) return null;
    final clue = _activeAcross ? _cellAcross[_activeKey] : _cellDown[_activeKey];
    return clue;
  }

  void _selectCell(int r, int c) {
    final key = '$r,$c';
    if (_puzzle.isBlocked(r, c)) return;
    setState(() {
      if (_activeKey == key) {
        if (_cellAcross.containsKey(key) && _cellDown.containsKey(key)) {
          _activeAcross = !_activeAcross;
        }
      } else {
        _activeKey = key;
        if (_activeAcross && !_cellAcross.containsKey(key)) {
          if (_cellDown.containsKey(key)) _activeAcross = false;
        } else if (!_activeAcross && !_cellDown.containsKey(key)) {
          if (_cellAcross.containsKey(key)) _activeAcross = true;
        }
      }
    });
  }

  void _inputLetter(String ch) {
    if (_activeKey == null) return;
    setState(() {
      _userInput[_activeKey!] = ch;
      _revealed.remove(_activeKey);
      _advance();
    });
  }

  void _advance() {
    final clue = _activeClue;
    if (clue == null) return;
    final idx = clue.cells.indexWhere((cell) => cell.key == _activeKey);
    if (idx >= 0 && idx < clue.cells.length - 1) {
      _activeKey = clue.cells[idx + 1].key;
    }
  }

  void _backspace() {
    if (_activeKey == null) return;
    setState(() {
      if (_userInput[_activeKey!] != null) {
        _userInput.remove(_activeKey!);
        _revealed.remove(_activeKey);
      } else {
        final clue = _activeClue;
        if (clue != null) {
          final idx =
              clue.cells.indexWhere((cell) => cell.key == _activeKey);
          if (idx > 0) {
            _activeKey = clue.cells[idx - 1].key;
            _userInput.remove(_activeKey);
            _revealed.remove(_activeKey);
          }
        }
      }
    });
  }

  void _toggleDirection() {
    if (_activeKey == null) return;
    if (_cellAcross.containsKey(_activeKey) &&
        _cellDown.containsKey(_activeKey)) {
      setState(() => _activeAcross = !_activeAcross);
    }
  }

  void _hint() {
    final wrong = _puzzle.solution.keys.where((key) {
      final expected = _puzzle.solution[key]!;
      final got = _userInput[key];
      return got != expected;
    }).toList();
    if (wrong.isEmpty) return;
    wrong.shuffle();
    final key = wrong.first;
    setState(() {
      _userInput[key] = _puzzle.solution[key]!;
      _revealed.add(key);
      _activeKey = key;
    });
  }

  void _clear() {
    setState(() {
      _userInput.clear();
      _revealed.clear();
    });
  }

  int get _filledCount => _puzzle.solution.keys
      .where((k) => _userInput[k] == _puzzle.solution[k])
      .length;

  void _verify() {
    final total = _puzzle.solution.length;
    final correct = _filledCount;
    final solved = correct == total;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(solved ? Icons.celebration_rounded : Icons.lightbulb_rounded,
                color: solved ? AppTheme.accent : Colors.orange),
            const SizedBox(width: 10),
            Text(solved ? ui.solvedTitle : ui.statusTitle),
          ],
        ),
        content: Text(solved ? ui.solvedBody : ui.statusBody(correct, total)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ui.close),
          ),
          if (solved)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(_buildPuzzle);
              },
              child: Text(ui.newPuzzle),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clue = _activeClue;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.difficulty.label),
        actions: [
          IconButton(
            tooltip: ui.clues,
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CluePanel(
                    puzzle: _puzzle,
                    ui: ui,
                    onSelect: (r, c) {
                      Navigator.pop(context);
                      _selectCell(r, c);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Novo puzzle',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_buildPuzzle),
          ),
        ],
      ),
      body: Column(
        children: [
          _ClueBar(
            ui: ui,
            clue: clue,
            across: _activeAcross,
            onToggle: _toggleDirection,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ui.progress(_filledCount, _puzzle.solution.length),
                    style: const TextStyle(color: AppTheme.muted)),
                Row(
                  children: [
                    _ActionChip(
                        icon: Icons.tips_and_updates_rounded,
                        label: ui.hint,
                        onTap: _hint),
                    const SizedBox(width: 8),
                    _ActionChip(
                        icon: Icons.cleaning_services_rounded,
                        label: ui.clear,
                        onTap: _clear),
                    const SizedBox(width: 8),
                    _ActionChip(
                        icon: Icons.check_circle_rounded,
                        label: ui.check,
                        onTap: _verify),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: CrosswordBoard(
                    puzzle: _puzzle,
                    userInput: _userInput,
                    revealed: _revealed,
                    activeKey: _activeKey,
                    activeAcross: _activeAcross,
                    cellNumber: _cellNumber,
                    activeClue: clue,
                    onCellTap: _selectCell,
                  ),
                ),
              ),
            ),
          ),
          Keyboard(
            alphabet: widget.language.alphabet,
            onLetter: _inputLetter,
            onBackspace: _backspace,
          ),
        ],
      ),
    );
  }
}

class _ClueBar extends StatelessWidget {
  final UiStrings ui;
  final Clue? clue;
  final bool across;
  final VoidCallback onToggle;

  const _ClueBar(
      {required this.ui,
      required this.clue,
      required this.across,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onToggle,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                clue != null ? '${clue!.number} ${across ? '→' : '↓'}' : '',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                clue?.text ?? ui.tapToStart,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.swap_horiz_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cellBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.primaryDark)),
          ],
        ),
      ),
    );
  }
}
