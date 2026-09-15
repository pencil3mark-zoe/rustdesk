/// Helpers for Android IMEs that keep text in a composing region until the
/// user commits a candidate. RustDesk must mirror only committed text to the
/// remote host; intermediate Pinyin/Hangul composition belongs to the local IME.

class CommittedTextMirror {
  CommittedTextMirror(this.committedValue);

  String committedValue;

  void reset(String value) {
    committedValue = value;
  }

  ({String oldValue, int backspaces, String insert})? update({
    required String text,
    required bool composing,
  }) {
    if (composing) {
      return null;
    }

    final oldValue = committedDiffOldValue(committedValue, text);
    final edit = computeCommittedTextEdit(oldValue, text);
    committedValue = text;
    return (
      oldValue: oldValue,
      backspaces: edit.backspaces,
      insert: edit.insert,
    );
  }
}

({int backspaces, String insert}) computeCommittedTextEdit(
    String oldValue, String newValue) {
  final oldRunes = oldValue.runes.toList(growable: false);
  final newRunes = newValue.runes.toList(growable: false);

  var common = 0;
  while (common < oldRunes.length &&
      common < newRunes.length &&
      oldRunes[common] == newRunes[common]) {
    common++;
  }

  return (
    backspaces: oldRunes.length - common,
    insert: String.fromCharCodes(newRunes.skip(common)),
  );
}

/// The hidden RustDesk input field is seeded with many `1` characters. A paste
/// may replace that sentinel buffer completely; in that case there is nothing
/// on the remote host to erase, so treat the old local buffer as empty.
String committedDiffOldValue(String oldValue, String newValue) {
  if (oldValue.isNotEmpty &&
      newValue.isNotEmpty &&
      oldValue.codeUnitAt(0) == 0x31 &&
      newValue.codeUnitAt(0) != 0x31) {
    return '';
  }
  return oldValue;
}

/// Android soft-keyboard text that contains non-ASCII Unicode should use
/// RustDesk's text/sequence path even when it is only one code point long.
///
/// On Linux/X11, the legacy single-character path becomes KeyEvent.chr and is
/// injected through Enigo key_down/key_up. Its libxdo fallback treats CJK text
/// as a key name (for example `我`) and can silently ignore it. KeyEvent.seq
/// instead uses xdo_enter_text_window, which is the correct text-input path.
bool shouldSendAsTextSequence(String text) {
  final runes = text.runes.toList(growable: false);
  if (runes.isEmpty) return false;
  if (runes.length > 1) return true;
  return runes.first > 0x7f;
}

const _autoInsertedBracketPairs = <String>{
  '""',
  '()',
  '[]',
  '<>',
  '{}',
  '”“',
  '《》',
  '（）',
  '【】',
};

bool isAutoInsertedBracketPair(
    String oldValue, int backspaces, String insert) {
  return oldValue.isNotEmpty &&
      backspaces == 0 &&
      _autoInsertedBracketPairs.contains(insert);
}
