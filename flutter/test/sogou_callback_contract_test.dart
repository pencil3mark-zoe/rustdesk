import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/soft_keyboard_commit_utils.dart';

// Framework/algorithm contracts, not evidence of delivery to a real Linux app.
void main() {
  testWidgets('rapid single and whole-sentence commits reach both callbacks',
      (tester) async {
    const seed = '1111';
    final controller = TextEditingController.fromValue(
      const TextEditingValue(
        text: seed,
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    final listenerMirror = CommittedTextMirror(seed);
    final changedMirror = CommittedTextMirror(seed);
    final fromListener = <String>[];
    final fromChanged = <String>[];
    controller.addListener(() {
      final value = controller.value;
      final edit = listenerMirror.update(
        text: value.text,
        composing: value.isComposingRangeValid,
      );
      if (edit != null && edit.insert.isNotEmpty) {
        expect(edit.backspaces, 0);
        fromListener.add(edit.insert);
      }
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TextField(
        controller: controller,
        onChanged: (text) {
          final edit = changedMirror.update(text: text, composing: false);
          if (edit != null && edit.insert.isNotEmpty) {
            expect(edit.backspaces, 0);
            fromChanged.add(edit.insert);
          }
        },
      )),
    ));
    await tester.showKeyboard(find.byType(TextField));
    var text = seed;
    final commits = <String>[
      '我', '爱', '你', '你好世界', '😀', 'é',
      ...List<String>.filled(100, '我今天吃饺子'),
    ];
    // No frame pump between commits: exercise rapid platform editing updates.
    for (final commit in commits) {
      text += commit;
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ));
    }
    await tester.pump();
    expect(fromListener, commits);
    expect(fromChanged, commits);
    expect(controller.text, seed + commits.join());
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('composition-only commit must not depend on onChanged',
      (tester) async {
    const seed = '1111';
    final controller = TextEditingController(text: seed);
    final mirror = CommittedTextMirror(seed);
    final inserted = <String>[];
    var changedCount = 0;
    controller.addListener(() {
      final value = controller.value;
      final edit = mirror.update(
        text: value.text,
        composing: value.isComposingRangeValid,
      );
      if (edit != null && edit.insert.isNotEmpty) inserted.add(edit.insert);
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TextField(
        controller: controller,
        onChanged: (_) => changedCount++,
      )),
    ));
    await tester.showKeyboard(find.byType(TextField));
    for (final value in const <TextEditingValue>[
      TextEditingValue(text: '1111nihao',
          selection: TextSelection.collapsed(offset: 9),
          composing: TextRange(start: 4, end: 9)),
      TextEditingValue(text: '1111你好',
          selection: TextSelection.collapsed(offset: 6),
          composing: TextRange(start: 4, end: 6)),
    ]) {
      tester.testTextInput.updateEditingValue(value);
    }
    await tester.pump();
    expect(inserted, isEmpty);
    final beforeCommit = changedCount;
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '1111你好', selection: TextSelection.collapsed(offset: 6),
      composing: TextRange.empty,
    ));
    await tester.pump();
    expect(changedCount, beforeCommit);
    expect(inserted, <String>['你好']);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  test('reset of sentinel must happen before controller notification', () {
    final mirror = CommittedTextMirror('1111我今天吃饺子');
    mirror.reset('1111');
    final edit = mirror.update(text: '1111', composing: false)!;
    expect(edit.backspaces, 0);
    expect(edit.insert, isEmpty);
  });

  test('empty text does not dispatch a key or text sequence', () {
    expect(shouldSendAsTextSequence(''), isFalse);
  });
}
