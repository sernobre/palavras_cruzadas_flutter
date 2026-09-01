import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

class Keyboard extends StatelessWidget {
  final List<String> alphabet;
  final void Function(String) onLetter;
  final VoidCallback onBackspace;

  const Keyboard({
    super.key,
    required this.alphabet,
    required this.onLetter,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E2130)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._chunk(alphabet, 10),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Apagar',
                  button: true,
                  child: _KeyButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onBackspace();
                    },
                    child: const Icon(Icons.backspace_rounded, color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _chunk(List<String> keys, int maxPerRow) {
    if (keys.isEmpty) return [];
    final rowCount = (keys.length / maxPerRow).ceil().clamp(1, 10);
    final base = keys.length ~/ rowCount;
    final remainder = keys.length % rowCount;
    final rows = <Widget>[];
    var offset = 0;
    for (var r = 0; r < rowCount; r++) {
      final count = base + (r < remainder ? 1 : 0);
      final rowKeys = keys.sublist(offset, offset + count);
      offset += count;
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowKeys
              .map((k) => Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 32, maxWidth: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Semantics(
                          label: 'Letra $k',
                          button: true,
                          child: _KeyButton(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onLetter(k);
                            },
                            child: Text(k,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ));
    }
    return rows;
  }
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _KeyButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF2A2E45) : AppTheme.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.white12 : AppTheme.cellBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ),
    );
  }
}
