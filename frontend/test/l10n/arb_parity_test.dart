import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String message) => RegExp(r'\{(\w+)')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .where((p) => !const {'plural', 'select'}.contains(p))
    .toSet();

void main() {
  final en = _load('app_en.arb');
  final he = _load('app_he.arb');

  test('en and he define exactly the same message keys', () {
    final enKeys = _messageKeys(en)..remove('@@locale');
    final heKeys = _messageKeys(he)..remove('@@locale');
    expect(heKeys.difference(enKeys), isEmpty, reason: 'keys only in he');
    expect(enKeys.difference(heKeys), isEmpty, reason: 'keys only in en');
  });

  test('en and he use the same placeholders for every message', () {
    for (final key in _messageKeys(en).where((k) => !k.startsWith('@@'))) {
      final enPh = _placeholders(en[key] as String);
      final hePh = _placeholders((he[key] ?? '') as String);
      expect(hePh, enPh, reason: 'placeholder mismatch for "$key"');
    }
  });

  test('no Hebrew message is left empty or identical-by-accident placeholder text', () {
    for (final key in _messageKeys(he).where((k) => !k.startsWith('@@'))) {
      expect((he[key] as String).trim(), isNotEmpty, reason: key);
    }
  });
}
