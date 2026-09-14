import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/models/soft_keyboard_commit_utils.dart';

void main() {
  group('CommittedTextMirror Sogou 9-key', () {
    test('holds Pinyin composing states and sends only final candidate', () {
      final mirror = CommittedTextMirror('1111');

      expect(mirror.update(text: '1111n', composing: true), isNull);
      expect(mirror.update(text: '1111ni', composing: true), isNull);
      expect(mirror.update(text: '1111nihao', composing: true), isNull);

      expect(
        mirror.update(text: '1111你好', composing: false),
        (oldValue: '1111', backspaces: 0, insert: '你好'),
      );
    });

    test('supports consecutive committed Chinese phrases', () {
      final mirror = CommittedTextMirror('1111你好');
      expect(mirror.update(text: '1111你好shi', composing: true), isNull);
      expect(mirror.update(text: '1111你好shijie', composing: true), isNull);
      expect(
        mirror.update(text: '1111你好世界', composing: false),
        (oldValue: '1111你好', backspaces: 0, insert: '世界'),
      );
    });

    test('same-length candidate replacement is not dropped', () {
      final mirror = CommittedTextMirror('1111你好');
      expect(
        mirror.update(text: '1111你们', composing: false),
        (oldValue: '1111你好', backspaces: 1, insert: '们'),
      );
    });

    test('committed deletion sends the exact number of backspaces', () {
      final mirror = CommittedTextMirror('1111中华人民共和国');
      expect(
        mirror.update(text: '1111中华人民共和', composing: false),
        (oldValue: '1111中华人民共和国', backspaces: 1, insert: ''),
      );
    });

    test('composition edits never change committed baseline', () {
      final mirror = CommittedTextMirror('1111今天');
      mirror.update(text: '1111今天wan', composing: true);
      mirror.update(text: '1111今天wanshang', composing: true);
      expect(mirror.committedValue, '1111今天');
      expect(
        mirror.update(text: '1111今天晚上', composing: false),
        (oldValue: '1111今天', backspaces: 0, insert: '晚上'),
      );
    });
  });

  group('committed text diff', () {
    test('paste replacing sentinel does not backspace the sentinel', () {
      final mirror = CommittedTextMirror('1111');
      expect(
        mirror.update(text: '测试粘贴', composing: false),
        (oldValue: '', backspaces: 0, insert: '测试粘贴'),
      );
    });

    test('counts Unicode code points rather than UTF-16 units', () {
      expect(
        computeCommittedTextEdit('1111😀', '1111'),
        (backspaces: 1, insert: ''),
      );
    });

    test('known auto-insert bracket pairs stay detectable', () {
      expect(isAutoInsertedBracketPair('1111', 0, '（）'), isTrue);
      expect(isAutoInsertedBracketPair('1111', 1, '（）'), isFalse);
    });
  });
}
