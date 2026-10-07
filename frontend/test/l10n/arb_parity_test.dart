import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Extracts ICU placeholder argument names from a message.
/// Handles ICU syntax like {count, plural, ...} and regular placeholders like {name}.
/// Returns only the argument name, filtering out 'plural' and 'select' keywords.
Set<String> icuArgumentNames(String message) => RegExp(r'\{\s*(\w+)\s*[,}]')
    .allMatches(message)
    .map((m) => m.group(1)!)
    .where((p) => !const {'plural', 'select'}.contains(p))
    .toSet();

void main() {
  final en = _load('app_en.arb');
  final he = _load('app_he.arb');

  group('icuArgumentNames', () {
    test('extracts argument from simple placeholder', () {
      expect(icuArgumentNames('Hi {name}!'), equals({'name'}));
    });

    test('extracts multiple arguments', () {
      expect(icuArgumentNames('{a} and {b}'), equals({'a', 'b'}));
    });

    test('returns empty set for plain text', () {
      expect(icuArgumentNames('Hello'), isEmpty);
    });

    test('extracts only argument name from ICU plural, not content', () {
      expect(
        icuArgumentNames('{count, plural, =0{No players} =1{1 player} other{{count} players}}'),
        equals({'count'}),
      );
    });

    test('extracts argument from Hebrew ICU plural', () {
      expect(
        icuArgumentNames('{count, plural, =0{אין שחקנים} =1{שחקן אחד} other{{count} שחקנים}}'),
        equals({'count'}),
      );
    });

    test('detects placeholder argument mismatch between English and Hebrew', () {
      final enArgs = icuArgumentNames('{count, plural, other{{count} players}}');
      final heArgs = icuArgumentNames('{cnt, plural, other{{cnt} שחקנים}}');
      expect(enArgs, isNot(heArgs), reason: 'should detect en has count, he has cnt');
    });
  });

  test('en and he define exactly the same message keys', () {
    final enKeys = _messageKeys(en);
    final heKeys = _messageKeys(he);
    expect(heKeys.difference(enKeys), isEmpty, reason: 'keys only in he');
    expect(enKeys.difference(heKeys), isEmpty, reason: 'keys only in en');
  });

  test('en and he use the same placeholders for every message', () {
    for (final key in _messageKeys(en)) {
      final enArgs = icuArgumentNames(en[key] as String);
      final heArgs = icuArgumentNames((he[key] ?? '') as String);
      expect(heArgs, enArgs, reason: 'placeholder mismatch for "$key"');
    }
  });

  test('no Hebrew message is left empty', () {
    for (final key in _messageKeys(he)) {
      expect((he[key] as String).trim(), isNotEmpty, reason: key);
    }
  });
}
