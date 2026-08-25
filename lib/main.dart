import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/screens/difficulty_screen.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

void main() {
  runApp(const PalavrasCruzadasApp());
}

class PalavrasCruzadasApp extends StatelessWidget {
  const PalavrasCruzadasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palavras Cruzadas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final language = languages[_selected];
    final ui = language.ui;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.grid_4x4_rounded,
                        color: AppTheme.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ui.appTitle,
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        Text(ui.subtitle,
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ui.homeHint,
                style: const TextStyle(fontSize: 15, color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              _LanguageSelector(
                selected: _selected,
                onSelect: (i) => setState(() => _selected = i),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: language.difficulties.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final d = language.difficulties[index];
                    return _DifficultyHomeCard(difficulty: d);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;

  const _LanguageSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cellBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < languages.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == i
                        ? AppTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    languages[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected == i
                          ? Colors.white
                          : AppTheme.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DifficultyHomeCard extends StatelessWidget {
  final Difficulty difficulty;

  const _DifficultyHomeCard({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = [
      AppTheme.accent,
      AppTheme.primary,
      Colors.deepOrange
    ][difficulty.id == 'facil'
        ? 0
        : difficulty.id == 'medio'
            ? 1
            : 2];

    final language =
        languages.firstWhere((l) => l.difficulties.contains(difficulty));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DifficultyScreen(
                language: language,
                difficulty: difficulty,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  difficulty.id == 'facil'
                      ? Icons.sentiment_satisfied_alt_rounded
                      : difficulty.id == 'medio'
                          ? Icons.sentiment_neutral_rounded
                          : Icons.sentiment_very_dissatisfied_rounded,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(difficulty.label,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(difficulty.description,
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                        '${difficulty.levels.where((l) => l.entries.isNotEmpty).length} níveis',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.muted, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
