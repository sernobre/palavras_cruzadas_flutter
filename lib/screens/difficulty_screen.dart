import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/models/crossword.dart';
import 'package:palavrascruzadas/screens/game_screen.dart';
import 'package:palavrascruzadas/services/progress.dart';
import 'package:palavrascruzadas/theme/app_theme.dart';
import 'package:palavrascruzadas/widgets/star_row.dart';

class DifficultyScreen extends StatefulWidget {
  final Language language;
  final Difficulty difficulty;

  const DifficultyScreen(
      {super.key, required this.language, required this.difficulty});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  late Future<ProgressStore> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = ProgressStore.load();
  }

  List<Level> get _levels =>
      widget.difficulty.levels.where((l) => l.entries.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(widget.difficulty.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.difficulty.label),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<ProgressStore>(
        future: _storeFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final store = snapshot.data!;
          final keys = _levels
              .map((l) => levelKey(widget.language.id, widget.difficulty.id,
                  l.name))
              .toList();
          final done = store.completedCount(keys);
          final stars = keys.fold(0, (s, k) => s + store.starsFor(k));

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(_difficultyIcon(widget.difficulty.id),
                            color: Colors.white, size: 34),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.difficulty.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              Text(widget.difficulty.description,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text('$done/${_levels.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const Text('níveis',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text('$stars estrelas conquistadas',
                            style: const TextStyle(
                                color: AppTheme.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _levels.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final level = _levels[index];
                        final originalIndex =
                            widget.difficulty.levels.indexOf(level);
                        final key = levelKey(widget.language.id,
                            widget.difficulty.id, level.name);
                        final earned = store.starsFor(key);
                        final completed = earned > 0;
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                    language: widget.language,
                                    difficulty: widget.difficulty,
                                    level: level,
                                    levelIndex: originalIndex,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text('${index + 1}',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: color)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(level.name,
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(
                                            completed
                                                ? 'Concluído'
                                                : 'Toca para jogar',
                                            style: const TextStyle(
                                                color: AppTheme.muted,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  StarRow(stars: earned),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppTheme.muted),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!store.isPro)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await store.setPro(true);
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Pro desbloqueado (demonstração local).')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.workspace_premium_rounded,
                                  color: Colors.white),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pro: dicas ilimitadas e sem anúncios',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text('Desbloquear',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _difficultyColor(String id) => id == 'facil'
      ? AppTheme.accent
      : id == 'medio'
          ? AppTheme.primary
          : Colors.deepOrange;

  IconData _difficultyIcon(String id) => id == 'facil'
      ? Icons.sentiment_satisfied_alt_rounded
      : id == 'medio'
          ? Icons.sentiment_neutral_rounded
          : Icons.sentiment_very_dissatisfied_rounded;
}
