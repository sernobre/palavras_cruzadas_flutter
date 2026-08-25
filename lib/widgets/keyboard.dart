import 'package:flutter/material.dart';
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
        color: Colors.white,
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
        children: [
          ..._chunk(alphabet, 10),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KeyButton(
                  onTap: onBackspace,
                  child: const Icon(Icons.backspace_rounded,
                      color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _chunk(List<String> keys, int size) {
    final rows = <Widget>[];
    for (var i = 0; i < keys.length; i += size) {
      final end = (i + size < keys.length) ? i + size : keys.length;
      final rowKeys = keys.sublist(i, end);
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: rowKeys
              .map((k) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _KeyButton(
                        onTap: () => onLetter(k),
                        child: Text(k,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryDark)),
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
    return Material(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.cellBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ),
    );
  }
}
