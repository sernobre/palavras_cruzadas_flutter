import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/models/generator.dart';
import 'package:palavrascruzadas/services/progress.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';
import 'package:palavrascruzadas/screens/paywall_screen.dart';
import 'package:palavrascruzadas/services/purchase_service.dart';
import 'package:palavrascruzadas/widgets/clue_panel.dart';
import 'package:palavrascruzadas/widgets/crossword_board.dart';
import 'package:palavrascruzadas/widgets/keyboard.dart';
import 'package:palavrascruzadas/widgets/star_row.dart';

class GameScreen extends StatefulWidget {
  final Language language;
  final Difficulty difficulty;
  final Level level;
  final int levelIndex;

  const GameScreen(
      {super.key,
      required this.language,
      required this.difficulty,
      required this.level,
      required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late CrosswordPuzzle _puzzle;
  final Map<String, String> _userInput = {};
  final Set<String> _revealed = {};
  final Set<String> _errorCells = {};
  String? _activeKey;
  bool _activeAcross = true;
  int _hintsUsed = 0;
  ProgressStore? _store;
  bool _autoCheck = false;
  bool _showFullAlphabet = false;
  bool _solved = false;

  late Map<String, Clue> _cellAcross;
  late Map<String, Clue> _cellDown;
  late Map<String, int> _cellNumber;

  List<String> _keyboardLetters = [];

  final List<Map<String, String>> _undoStack = [];

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _timerRunning = false;

  UiStrings get ui => widget.language.ui;
  bool get _isDaily => widget.difficulty.id == 'diario';
  static const int freeHintsPerLevel = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildPuzzle();
    ProgressStore.load().then((store) {
      if (!mounted) return;
      setState(() => _store = store);
      _restoreState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _persistState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _persistState();
  }

  String get _levelKey =>
      levelKey(widget.language.id, widget.difficulty.id, widget.level.name);

  int? get _nextLevelIndex {
    final levels = widget.difficulty.levels;
    for (var i = widget.levelIndex + 1; i < levels.length; i++) {
      if (levels[i].entries.isNotEmpty) return i;
    }
    return null;
  }

  void _startTimer() {
    if (_timerRunning || _solved) return;
    _timerRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _solved) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  void _buildPuzzle() {
    final entries = [...widget.level.entries];
    entries.shuffle();
    _puzzle = generateCrossword(entries, alphabet: widget.language.alphabet.toSet());
    _userInput.clear();
    _revealed.clear();
    _errorCells.clear();
    _hintsUsed = 0;
    _elapsedSeconds = 0;
    _solved = false;
    _undoStack.clear();
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
        : _puzzle.downClues.isNotEmpty
            ? _puzzle.downClues.first.cells.first.key
            : null;
    _activeAcross = true;
    _updateKeyboardLetters();
    _stopTimer();
  }

  void _updateKeyboardLetters() {
    final needed = _puzzle.solution.values.toSet();
    if (needed.isEmpty) {
      _keyboardLetters = List<String>.from(widget.language.alphabet);
      return;
    }
    final isHard = widget.difficulty.id == 'dificil' || _isDaily;
    if (isHard) {
      _keyboardLetters = List<String>.from(widget.language.alphabet);
    } else if (widget.difficulty.id == 'medio') {
      final pool = widget.language.alphabet.where((c) => !needed.contains(c)).toList();
      pool.shuffle();
      final extras = pool.take(5).toSet();
      final combined = {...needed, ...extras};
      _keyboardLetters = widget.language.alphabet.where(combined.contains).toList();
    } else {
      _keyboardLetters = widget.language.alphabet.where(needed.contains).toList();
      if (_keyboardLetters.isEmpty) {
        _keyboardLetters = List<String>.from(widget.language.alphabet);
      }
    }
  }

  Future<void> _restoreState() async {
    final data = _store?.loadGameState(_levelKey);
    if (data == null) return;
    try {
      final input = (data['input'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      final revealed = (data['revealed'] as List).map((e) => e.toString()).toSet();
      final hints = data['hints'] as int? ?? 0;
      final elapsed = data['elapsed'] as int? ?? 0;
      if (!mounted) return;
      setState(() {
        _userInput.addAll(input);
        _revealed.addAll(revealed);
        _hintsUsed = hints;
        _elapsedSeconds = elapsed;
      });
      _recomputeErrors();
      _startTimer();
    } catch (_) {}
  }

  Future<void> _persistState() async {
    if (_store == null || _solved) return;
    await _store!.saveGameState(_levelKey, _userInput, _revealed, _hintsUsed, _elapsedSeconds);
  }

  Clue? get _activeClue {
    if (_activeKey == null) return null;
    return _activeAcross ? _cellAcross[_activeKey] : _cellDown[_activeKey];
  }

  void _selectCell(int r, int c) {
    final key = '$r,$c';
    if (_puzzle.isBlocked(r, c)) return;
    HapticFeedback.selectionClick();
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
    _startTimer();
  }

  void _pushUndo() {
    _undoStack.add(Map<String, String>.from(_userInput));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _inputLetter(String ch) {
    if (_activeKey == null) return;
    _pushUndo();
    setState(() {
      _userInput[_activeKey!] = ch;
      _revealed.remove(_activeKey);
      _advance();
    });
    _recomputeErrors();
    _persistState();
    _checkSolved();
    _startTimer();
  }

  void _advance() {
    final clue = _activeClue;
    if (clue == null) return;
    final idx = clue.cells.indexWhere((cell) => cell.key == _activeKey);
    if (idx >= 0 && idx < clue.cells.length - 1) {
      _activeKey = clue.cells[idx + 1].key;
    } else {
      final all = [..._puzzle.acrossClues, ..._puzzle.downClues];
      final currentIdx = all.indexWhere((c) => c == clue);
      if (currentIdx >= 0 && currentIdx < all.length - 1) {
        _activeKey = all[currentIdx + 1].cells.first.key;
        _activeAcross = all[currentIdx + 1].across;
      }
    }
  }

  void _backspace() {
    if (_activeKey == null) return;
    _pushUndo();
    setState(() {
      if (_userInput[_activeKey!] != null) {
        _userInput.remove(_activeKey!);
        _revealed.remove(_activeKey);
      } else {
        final clue = _activeClue;
        if (clue != null) {
          final idx = clue.cells.indexWhere((cell) => cell.key == _activeKey);
          if (idx > 0) {
            _activeKey = clue.cells[idx - 1].key;
            _userInput.remove(_activeKey);
            _revealed.remove(_activeKey);
          }
        }
      }
    });
    _recomputeErrors();
    _persistState();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      final prev = _undoStack.removeLast();
      _userInput
        ..clear()
        ..addAll(prev);
    });
    _recomputeErrors();
    _persistState();
  }

  void _toggleDirection() {
    if (_activeKey == null) return;
    if (_cellAcross.containsKey(_activeKey) && _cellDown.containsKey(_activeKey)) {
      setState(() => _activeAcross = !_activeAcross);
    }
  }

  void _recomputeErrors() {
    if (!_autoCheck) {
      if (_errorCells.isNotEmpty) setState(() => _errorCells.clear());
      return;
    }
    final errors = <String>{};
    for (final e in _userInput.entries) {
      final expected = _puzzle.solution[e.key];
      if (expected != null && e.value != expected) errors.add(e.key);
    }
    if (errors.length != _errorCells.length || !errors.containsAll(_errorCells)) {
      setState(() {
        _errorCells
          ..clear()
          ..addAll(errors);
      });
    }
  }

  void _hint({bool wholeWord = false}) {
    List<String> wrong;
    if (wholeWord && _activeClue != null) {
      wrong = _activeClue!.cells.map((c) => c.key).where((k) => _userInput[k] != _puzzle.solution[k]).toList();
      if (wrong.isEmpty) return;
    } else {
      wrong = _puzzle.solution.keys.where((key) => _userInput[key] != _puzzle.solution[key]).toList();
      if (wrong.isEmpty) return;
      wrong.shuffle();
      wrong = [wrong.first];
    }

    final isPro = _store?.isPro ?? false;
    final cost = wholeWord ? wrong.length : 1;
    if (!isPro && _hintsUsed + cost > freeHintsPerLevel) {
      _showProDialog();
      return;
    }

    _pushUndo();
    setState(() {
      for (final k in wrong) {
        _userInput[k] = _puzzle.solution[k]!;
        _revealed.add(k);
      }
      _activeKey = wrong.last;
      _hintsUsed += cost;
    });
    HapticFeedback.mediumImpact();
    _recomputeErrors();
    _persistState();
    _checkSolved();
  }

  void _showProDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Dicas esgotadas'),
        content: Text('Usaste as tuas dicas grátis deste nível. Desbloqueia o Pro por ${priceFor(widget.language.variantId)} para dicas ilimitadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mais tarde')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openPaywall();
            },
            child: const Text('Ver Pro'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaywall() async {
    final s = _store ?? await ProgressStore.load();
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PaywallScreen(variantId: widget.language.variantId, store: s)));
    if (ok == true && mounted) setState(() => _store = s);
  }

  Future<void> _unlockPro() async {
    final store = _store ?? await ProgressStore.load();
    await store.setPro(true);
    setState(() => _store = store);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pro desbloqueado (demonstração local).')),
      );
    }
  }

  void _clearWord() {
    final clue = _activeClue;
    if (clue == null) return;
    _pushUndo();
    setState(() {
      for (final cell in clue.cells) {
        if (!_revealed.contains(cell.key)) _userInput.remove(cell.key);
      }
    });
    _recomputeErrors();
    _persistState();
  }

  void _clearAll() {
    _pushUndo();
    setState(() {
      final toRemove = _userInput.keys.where((k) => !_revealed.contains(k)).toList();
      for (final k in toRemove) {
        _userInput.remove(k);
      }
    });
    _recomputeErrors();
    _persistState();
  }

  int get _filledCount => _puzzle.solution.keys.where((k) => _userInput[k] == _puzzle.solution[k]).length;

  void _checkSolved() {
    if (_filledCount == _puzzle.solution.length && !_solved) {
      _onSolved();
    }
  }

  void _onSolved() {
    _solved = true;
    _stopTimer();
    _store?.clearGameState(_levelKey);
    final stars = _hintsUsed == 0
        ? 3
        : _hintsUsed <= 2
            ? 2
            : 1;
    _store?.recordStars(_levelKey, stars);
    _store?.recordBestTime(_levelKey, _elapsedSeconds);
    if (_isDaily) _store?.recordDaily(widget.language.id, DateTime.now());
    HapticFeedback.heavyImpact();
    _showSolvedDialog(stars);
  }

  void _verify() {
    final total = _puzzle.solution.length;
    final correct = _filledCount;
    final solved = correct == total;
    if (solved && !_solved) {
      _onSolved();
      return;
    }
    if (solved) return;
    setState(() => _autoCheck = true);
    _recomputeErrors();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$correct/$total corretas — erros destacados a vermelho')),
    );
  }

  void _showSolvedDialog(int stars) {
    final nextIndex = _nextLevelIndex;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: AppTheme.accent),
            const SizedBox(width: 10),
            Text(ui.solvedTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ui.solvedBody),
            const SizedBox(height: 8),
            Text('Tempo: ${_formatTime(_elapsedSeconds)}', style: const TextStyle(color: AppTheme.muted)),
            if (_store?.bestTimeFor(_levelKey) != null)
              Text('Melhor: ${_formatTime(_store!.bestTimeFor(_levelKey)!)}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Center(child: StarRow(stars: stars, size: 34)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(ui.close)),
          if (nextIndex == null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Concluído'),
            ),
          if (nextIndex != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      language: widget.language,
                      difficulty: widget.difficulty,
                      level: widget.difficulty.levels[nextIndex],
                      levelIndex: nextIndex,
                    ),
                  ),
                );
              },
              child: const Text('Próximo nível'),
            ),
        ],
      ),
    );
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final clue = _activeClue;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.difficulty.label} · ${widget.level.name}'),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(_formatTime(_elapsedSeconds),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
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
            tooltip: _showFullAlphabet ? 'Teclado filtrado' : 'Alfabeto completo',
            icon: Icon(_showFullAlphabet ? Icons.filter_alt_rounded : Icons.abc_rounded),
            onPressed: () => setState(() => _showFullAlphabet = !_showFullAlphabet),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'autoCheck') setState(() => _autoCheck = !_autoCheck);
              if (v == 'undo') _undo();
              if (v == 'hint_word') _hint(wholeWord: true);
              if (v == 'new') setState(_buildPuzzle);
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'autoCheck', checked: _autoCheck, child: const Text('Verificação automática')),
              const PopupMenuItem(value: 'undo', child: Text('Desfazer')),
              const PopupMenuItem(value: 'hint_word', child: Text('Dica: palavra')),
              const PopupMenuItem(value: 'new', child: Text('Novo puzzle')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _ClueBar(ui: ui, clue: clue, across: _activeAcross, onToggle: _toggleDirection),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(ui.progress(_filledCount, _puzzle.solution.length),
                    style: const TextStyle(color: AppTheme.muted)),
                if (_hintsUsed > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$_hintsUsed dicas',
                        style: const TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionChip(
                            icon: Icons.undo_rounded, label: 'Desfazer', onTap: _undoStack.isEmpty ? null : _undo),
                        const SizedBox(width: 6),
                        _ActionChip(icon: Icons.tips_and_updates_rounded, label: ui.hint, onTap: () => _hint()),
                        const SizedBox(width: 6),
                        _ActionChip(icon: Icons.cleaning_services_rounded, label: ui.clear, onTap: _clearWord),
                        const SizedBox(width: 6),
                        _ActionChip(icon: Icons.check_circle_rounded, label: ui.check, onTap: _verify),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_autoCheck)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.visibility_rounded, size: 14, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  const Text('Verificação automática ativa', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _autoCheck = false),
                    child: const Text('Desativar', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                  ),
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
                    errorCells: _errorCells,
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
            alphabet: _showFullAlphabet
                ? widget.language.alphabet
                : (_keyboardLetters.isEmpty ? widget.language.alphabet : _keyboardLetters),
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

  const _ClueBar({required this.ui, required this.clue, required this.across, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onToggle,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
              child: Text(
                clue != null ? '${clue!.number} ${across ? '→' : '↓'}' : '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
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
  final VoidCallback? onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cellBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: enabled ? AppTheme.primary : AppTheme.muted),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 11, color: enabled ? AppTheme.primaryDark : AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
