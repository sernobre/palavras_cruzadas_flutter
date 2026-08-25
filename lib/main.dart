import 'package:flutter/material.dart';
import 'package:palavrascruzadas/data/words.dart';
import 'package:palavrascruzadas/screens/game_screen.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Palavras Cruzadas',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        Text('Português de Portugal',
                            style: TextStyle(color: AppTheme.muted, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Escolhe um nível de dificuldade para começar a resolver o puzzle.',
                style: TextStyle(fontSize: 15, color: AppTheme.muted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: difficulties.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final d = difficulties[index];
                    return _DifficultyCard(difficulty: d, width: size.width);
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

class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final double width;

  const _DifficultyCard({required this.difficulty, required this.width});

  @override
  Widget build(BuildContext context) {
    final color = [
      AppTheme.accent,
      AppTheme.primary,
      Colors.deepOrange
    ][difficulties.indexOf(difficulty) % 3];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameScreen(difficulty: difficulty),
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
