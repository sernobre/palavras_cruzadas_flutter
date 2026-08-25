import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palavrascruzadas/data/languages.dart';
import 'package:palavrascruzadas/screens/game_screen.dart';
import 'package:palavrascruzadas/widgets/crossword_board.dart';
import 'package:palavrascruzadas/widgets/keyboard.dart';

void main() {
  testWidgets('typing a letter shows it on the board', (tester) async {
    final languages = await loadLanguages();
    await tester.pumpWidget(MaterialApp(
      home: GameScreen(
        language: languages.first,
        difficulty: languages.first.difficulties.first,
        level: languages.first.difficulties.first.levels.first,
        levelIndex: 0,
      ),
    ));
    await tester.pumpAndSettle();

    // Type a letter using the keyboard.
    final key = find.descendant(
        of: find.byType(Keyboard), matching: find.text('A'));
    expect(key, findsOneWidget);
    await tester.tap(key);
    await tester.pumpAndSettle();

    // The letter should now appear inside the board.
    final onBoard = find.descendant(
        of: find.byType(CrosswordBoard), matching: find.text('A'));
    expect(onBoard, findsWidgets);
  });
}
