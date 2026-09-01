import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/main.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final List<Language> languages;
  final int selected;
  final void Function(int) onSelect;

  const SettingsScreen({super.key, required this.languages, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<(int, Language)>>{};
    for (var i = 0; i < languages.length; i++) {
      final base = languages[i].baseId;
      groups.putIfAbsent(base, () => []).add((i, languages[i]));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Opções')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (_, mode, __) => SwitchListTile(
              title: const Text('Tema escuro'),
              subtitle: Text(mode == ThemeMode.dark ? 'Ativo' : 'Inativo'),
              value: mode == ThemeMode.dark,
              onChanged: (v) => themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          const Divider(),
          const Text('Idioma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(languages[selected].label, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          const SizedBox(height: 12),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted, letterSpacing: 0.8)),
            ),
            for (final pair in entry.value)
              Card(
                child: ListTile(
                  title: Text(pair.$2.label),
                  subtitle: Text(pair.$2.ui.subtitle),
                  trailing: selected == pair.$1 ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                  selected: selected == pair.$1,
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    onSelect(pair.$1);
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
