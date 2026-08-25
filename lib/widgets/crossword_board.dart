import 'package:flutter/material.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

class CrosswordBoard extends StatelessWidget {
  final CrosswordPuzzle puzzle;
  final Map<String, String> userInput;
  final Set<String> revealed;
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
    required this.activeKey,
    required this.activeAcross,
    required this.cellNumber,
    required this.activeClue,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = ((MediaQuery.of(context).size.width - 32) / puzzle.width)
        .clamp(26.0, 46.0);

    final activeKeys = <String>{};
    if (activeClue != null) {
      for (final cell in activeClue!.cells) {
        activeKeys.add(cell.key);
      }
    }

    final rows = <Widget>[];
    for (var r = 0; r < puzzle.height; r++) {
      final cells = <Widget>[];
      for (var c = 0; c < puzzle.width; c++) {
        final key = '$r,$c';
        if (puzzle.isBlocked(r, c)) {
          cells.add(SizedBox(width: cellSize, height: cellSize));
          continue;
        }
        final isActive = key == activeKey;
        final inClue = activeKeys.contains(key);
        final isRevealed = revealed.contains(key);
        final number = cellNumber[key];

        cells.add(GestureDetector(
          onTap: () => onCellTap(r, c),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.activeCell
                  : inClue
                      ? AppTheme.activeClue
                      : isRevealed
                          ? AppTheme.correct
                          : Colors.white,
              border: Border.all(color: AppTheme.cellBorder, width: 1),
            ),
            child: Stack(
              children: [
                if (number != null)
                  Positioned(
                    top: 2,
                    left: 3,
                    child: Text('$number',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.muted)),
                  ),
                Center(
                  child: Text(
                    userInput[key] ?? '',
                    style: TextStyle(
                      fontSize: cellSize * 0.5,
                      fontWeight: FontWeight.w700,
                      color: isRevealed ? AppTheme.accent : AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      }
      rows.add(Row(children: cells));
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.block,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(children: rows),
    );
  }
}
