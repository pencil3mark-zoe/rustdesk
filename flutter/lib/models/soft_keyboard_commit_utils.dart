/// Helpers for Android IMEs that keep text in a composing region until the
/// user commits a candidate. RustDesk must mirror only committed text to the
/// remote host; intermediate Pinyin/Hangul composition belongs to the local IME.

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
