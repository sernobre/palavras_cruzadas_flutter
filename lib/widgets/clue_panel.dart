import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

class CluePanel extends StatefulWidget {
  final CrosswordPuzzle puzzle;
  final UiStrings ui;
  final void Function(int r, int c) onSelect;

  const CluePanel(
      {super.key,
      required this.puzzle,
      required this.ui,
      required this.onSelect});

  @override
  State<CluePanel> createState() => _CluePanelState();
}

class _CluePanelState extends State<CluePanel> {
  bool _showAcross = true;

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final clues = _showAcross ? widget.puzzle.acrossClues : widget.puzzle.downClues;
    return Scaffold(
      appBar: AppBar(
        title: Text(ui.clues),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _Tab(
                  label: ui.across,
                  selected: _showAcross,
                  onTap: () => setState(() => _showAcross = true),
                ),
                _Tab(
                  label: ui.down,
                  selected: !_showAcross,
                  onTap: () => setState(() => _showAcross = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: clues.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final clue = clues[index];
                return Card(
                  child: ListTile(
                    onTap: () => widget.onSelect(
                        clue.cells.first.r, clue.cells.first.c),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Text('${clue.number}',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(clue.text),
                    subtitle: Text(
                      '${clue.answer.length} ${widget.ui.lettersWord}',
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: AppTheme.muted),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}
