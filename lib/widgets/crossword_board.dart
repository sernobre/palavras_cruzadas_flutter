import 'package:flutter/material.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

class CrosswordBoard extends StatelessWidget {
  final CrosswordPuzzle puzzle;
  final Map<String, String> userInput;
  final Set<String> revealed;
  final Set<String> errorCells;
  final String? activeKey;
  final bool activeAcross;
  final Map<String, int> cellNumber;
  final Clue? activeClue;
  final void Function(int r, int c) onCellTap;

  const CrosswordBoard({
    super.key,
    required this.puzzle,
    required this.userInput,
    required this.revealed,
    this.errorCells = const {},
    required this.activeKey,
    required this.activeAcross,
    required this.cellNumber,
    required this.activeClue,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cellSize = ((MediaQuery.of(context).size.width - 32) / puzzle.width).clamp(26.0, 46.0);

    final activeKeys = <String>{};
    if (activeClue != null) {
      for (final cell in activeClue!.cells) {
        activeKeys.add(cell.key);
      }
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D2E) : AppTheme.block,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < puzzle.height; r++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < puzzle.width; c++)
                    _Cell(
                      r: r,
                      c: c,
                      puzzle: puzzle,
                      userInput: userInput,
                      revealed: revealed,
                      errorCells: errorCells,
                      activeKey: activeKey,
                      activeKeys: activeKeys,
                      cellNumber: cellNumber,
                      cellSize: cellSize,
                      onTap: onCellTap,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int r;
  final int c;
  final CrosswordPuzzle puzzle;
  final Map<String, String> userInput;
  final Set<String> revealed;
  final Set<String> errorCells;
  final String? activeKey;
  final Set<String> activeKeys;
  final Map<String, int> cellNumber;
  final double cellSize;
  final void Function(int r, int c) onTap;

  const _Cell({
    required this.r,
    required this.c,
    required this.puzzle,
    required this.userInput,
    required this.revealed,
    required this.errorCells,
    required this.activeKey,
    required this.activeKeys,
    required this.cellNumber,
    required this.cellSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final key = '$r,$c';
    if (puzzle.isBlocked(r, c)) {
      return Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0F111A)
              : const Color(0xFF1B1F2A),
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
        ),
        child: CustomPaint(
          painter: _BlockPainter(),
        ),
      );
    }

    final isActive = key == activeKey;
    final inClue = activeKeys.contains(key);
    final isRevealed = revealed.contains(key);
    final isError = errorCells.contains(key);
    final number = cellNumber[key];
    final letter = userInput[key] ?? '';

    Color bg;
    if (isActive) {
      bg = AppTheme.activeCell;
    } else if (isError) {
      bg = AppTheme.error;
    } else if (inClue) {
      bg = AppTheme.activeClue;
    } else if (isRevealed) {
      bg = AppTheme.correct;
    } else {
      bg = Colors.white;
    }

    return Semantics(
      label: number != null ? 'Casa $number, ${letter.isEmpty ? 'vazia' : letter}' : letter.isEmpty ? 'Casa vazia' : letter,
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: () => onTap(r, c),
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: AppTheme.cellBorder, width: 1),
          ),
          child: Stack(
            children: [
              if (number != null)
                Positioned(
                  top: 2,
                  left: 3,
                  child: Text(
                    '$number',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppTheme.muted),
                  ),
                ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    letter,
                    key: ValueKey('$key-$letter'),
                    style: TextStyle(
                      fontSize: cellSize * 0.48,
                      fontWeight: FontWeight.w700,
                      color: isRevealed
                          ? AppTheme.accent
                          : isError
                              ? AppTheme.errorText
                              : AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width; i += 6) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
