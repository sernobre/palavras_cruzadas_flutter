import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/screens/difficulty_screen.dart';
import 'package:palavrascruzadas/screens/game_screen.dart';
import 'package:palavrascruzadas/services/progress.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languages = await loadLanguages();
  runApp(PalavrasCruzadasApp(languages: languages));
}

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

class PalavrasCruzadasApp extends StatelessWidget {
  final List<Language> languages;

  const PalavrasCruzadasApp({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Palavras Cruzadas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: HomeScreen(languages: languages),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Language> languages;

  const HomeScreen({super.key, required this.languages});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;
  ProgressStore? _store;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final store = await ProgressStore.load();
    if (mounted) setState(() => _store = store);
  }

  List<String> get _levelKeys {
    final keys = <String>[];
    for (final l in widget.languages) {
      for (final d in l.difficulties) {
        for (final lv in d.levels) {
          if (lv.entries.isNotEmpty) keys.add(levelKey(l.id, d.id, lv.name));
        }
      }
    }
    return keys;
  }

  int get _totalLevels => _levelKeys.length;
  int get _completedLevels => _store?.completedCount(_levelKeys) ?? 0;

  @override
  Widget build(BuildContext context) {
    final language = widget.languages[_selected];
    final ui = language.ui;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.grid_4x4_rounded, color: AppTheme.primary, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ui.appTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                            Text(ui.subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: themeModeNotifier,
                        builder: (_, mode, __) => IconButton(
                          tooltip: mode == ThemeMode.dark ? 'Modo claro' : 'Modo escuro',
                          icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                          onPressed: () {
                            themeModeNotifier.value =
                                mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(ui.homeHint, style: const TextStyle(fontSize: 15, color: AppTheme.muted)),
                  const SizedBox(height: 16),
                  _ProgressHeader(store: _store, completed: _completedLevels, total: _totalLevels),
                  const SizedBox(height: 12),
                  _DailyCard(store: _store, language: language, onPlay: () => _openDaily(language)),
                  const SizedBox(height: 16),
                  _LanguageSelector(
                    languages: widget.languages,
                    selected: _selected,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList.separated(
                itemCount: language.difficulties.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final d = language.difficulties[index];
                  return _DifficultyHomeCard(language: language, difficulty: d, onReturn: () => _loadStore());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDaily(Language language) async {
    final daily = buildDailyDifficulty(language, DateTime.now());
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(language: language, difficulty: daily, level: daily.levels.first, levelIndex: 0)),
    );
    _loadStore();
  }
}

class _ProgressHeader extends StatelessWidget {
  final ProgressStore? store;
  final int completed;
  final int total;

  const _ProgressHeader({required this.store, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final stars = store?.totalStars() ?? 0;
    final streak = store?.streak ?? 0;
    return Row(
      children: [
        Expanded(child: _Stat(icon: Icons.star_rounded, color: AppTheme.accent, value: '$stars', label: 'estrelas')),
        const SizedBox(width: 12),
        Expanded(child: _Stat(icon: Icons.local_fire_department_rounded, color: Colors.deepOrange, value: '$streak', label: 'dias seguidos')),
        const SizedBox(width: 12),
        Expanded(child: _Stat(icon: Icons.check_circle_rounded, color: AppTheme.primary, value: '$completed/$total', label: 'níveis')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  final ProgressStore? store;
  final Language language;
  final VoidCallback onPlay;

  const _DailyCard({required this.store, required this.language, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final done = store?.dailyCompletedToday(language.id, DateTime.now()) ?? false;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPlay,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Puzzle Diário',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(done ? 'Concluído hoje — volta amanhã!' : 'Um desafio novo todos os dias',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(done ? 'Feito' : 'Jogar', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final List<Language> languages;
  final int selected;
  final void Function(int) onSelect;

  const _LanguageSelector({required this.languages, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2130) : AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cellBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < languages.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Semantics(
                  selected: selected == i,
                  button: true,
                  label: languages[i].label,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == i ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      languages[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600, color: selected == i ? Colors.white : AppTheme.muted),
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
  final Language language;
  final Difficulty difficulty;
  final VoidCallback? onReturn;

  const _DifficultyHomeCard({required this.language, required this.difficulty, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final color = [AppTheme.accent, AppTheme.primary, Colors.deepOrange][difficulty.id == 'facil' ? 0 : difficulty.id == 'medio' ? 1 : 2];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => DifficultyScreen(language: language, difficulty: difficulty)))
              .then((_) => onReturn?.call());
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
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
                    Text(difficulty.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(difficulty.description, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${difficulty.levels.where((l) => l.entries.isNotEmpty).length} níveis',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
