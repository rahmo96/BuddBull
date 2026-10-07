import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files/directories (relative to `frontend/`) whose user-visible text must
/// come from AppLocalizations. Migration tasks append to this list.
const List<String> migratedPaths = <String>[
  'lib/features/profile/presentation/widgets/language_sheet.dart',
];

Iterable<File> _dartFiles(String path) {
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.file) return [File(path)];
  if (type == FileSystemEntityType.directory) {
    return Directory(path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
  }
  return const [];
}

/// Removes content inside /* */ blocks from the source.
String _stripBlockComments(String source) {
  return source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
}

/// Removes interpolation (${...} and $ident) from a string literal.
String _removeInterpolation(String literal) {
  // Remove ${...}
  var result = literal.replaceAll(RegExp(r'\$\{[^}]*\}'), '');
  // Remove $ident
  result = result.replaceAll(RegExp(r'\$\w+'), '');
  return result;
}

/// Checks if a string (after interpolation removal) contains letters.
bool _hasLetters(String str) {
  return RegExp(r'[A-Za-z֐-׿]').hasMatch(str);
}

/// Extracts hardcoded string literals from Dart source code.
/// Returns a list of offenders in the format "line N: <text>".
List<String> findHardcodedStrings(String source) {
  // Remove block comments first
  final sourceNoBlocks = _stripBlockComments(source);
  final offenders = <String>[];

  // Patterns for detecting hardcoded strings.
  // These match contexts where string literals are hardcoded (not from l10n or identifiers).
  final hardcodedPatterns = [
    // Text/SelectableText/Text.rich/TextSpan constructors with string literals
    RegExp(
      r'''(Text|SelectableText|Text\.rich|TextSpan)\s*\(\s*(?:const\s+)?(?:Text\s*\()?\s*['"]([^'"\\]|\\.)*['"]''',
      multiLine: true,
      dotAll: true,
    ),
    // Ternary in Text: Text(cond ? 'On' : 'Off')
    RegExp(
      r'''Text\s*\([^()]*\?\s*['"]([^'"\\]|\\.)*['"]''',
      multiLine: true,
      dotAll: true,
    ),
    // Named string arguments: labelText: 'Foo', title: 'Bar', etc.
    RegExp(
      r'''\b(labelText|hintText|helperText|errorText|tooltip|semanticLabel|semanticsLabel|label|title|subtitle|content|message|text|hint|description|prefixText|suffixText|counterText|confirmText|cancelText|buttonText|placeholder|heading)\s*:\s*(?:const\s+)?(?:Text\s*\()?\s*['"]([^'"\\]|\\.)*['"]''',
      multiLine: true,
      dotAll: true,
    ),
    // Ternary with => or after ?: validator: (v) => v!.isEmpty ? 'Required' : null
    RegExp(
      r'''\?\s*['"]([^'"\\]|\\.)*['"]''',
      multiLine: true,
      dotAll: true,
    ),
    // return or => statements with string literals
    RegExp(
      r'''(?:return|=>)\s*['"]([^'"\\]|\\.)*['"]''',
      multiLine: true,
      dotAll: true,
    ),
  ];

  // Find all matches of hardcoded patterns
  for (final pattern in hardcodedPatterns) {
    for (final match in pattern.allMatches(sourceNoBlocks)) {
      final matchText = match.group(0)!;

      // Skip if this match spans across l10n-ignore marker
      final matchStart = match.start;
      final matchEnd = match.end;
      final lineStart = sourceNoBlocks.lastIndexOf('\n', matchStart) + 1;
      final lineEnd = sourceNoBlocks.indexOf('\n', matchEnd);
      final endIdx = lineEnd == -1 ? sourceNoBlocks.length : lineEnd;
      final lineText = sourceNoBlocks.substring(lineStart, endIdx);

      if (lineText.contains('l10n-ignore')) continue;
      if (lineText.trimLeft().startsWith('//')) continue;

      // Extract the string literal content and check for letters
      final stringMatch =
          RegExp(r'''['"]([^'"\\]|\\.)*['"]''').firstMatch(matchText);
      if (stringMatch != null) {
        final quotedStr = stringMatch.group(0)!;
        final content = quotedStr.substring(1, quotedStr.length - 1);

        // Remove interpolation
        final noInterp = _removeInterpolation(content);

        // Skip if only interpolation or no letters
        if (noInterp.isEmpty || !_hasLetters(noInterp)) continue;

        // Calculate line number
        final lineNum = sourceNoBlocks.substring(0, lineStart).split('\n').length;
        offenders.add('line $lineNum: ${lineText.trim()}');
      }
    }
  }

  // Remove duplicates
  return offenders.toSet().toList()..sort();
}

void main() {
  group('findHardcodedStrings unit tests', () {
    test('flags Text(\'Save\')', () {
      final result = findHardcodedStrings("Text('Save')");
      expect(result, isNotEmpty);
    });

    test('flags Text with multiline string', () {
      final result = findHardcodedStrings("Text(\n  'Save',\n)");
      expect(result, isNotEmpty);
    });

    test('flags const Text("Save")', () {
      final result = findHardcodedStrings('const Text("Save")');
      expect(result, isNotEmpty);
    });

    test('flags ternary Text(on ? \'On\' : \'Off\')', () {
      final result = findHardcodedStrings("Text(on ? 'On' : 'Off')");
      expect(result, isNotEmpty);
    });

    test('flags labelText named argument', () {
      final result = findHardcodedStrings("AppButton(labelText: 'Save')");
      expect(result, isNotEmpty);
    });

    test('flags hintText named argument', () {
      final result = findHardcodedStrings("InputDecoration(hint: 'x y')");
      expect(result, isNotEmpty);
    });

    test('flags validator return', () {
      final result = findHardcodedStrings("validator: (v) => v!.isEmpty ? 'Required' : null");
      expect(result, isNotEmpty);
    });

    test('flags return statement', () {
      final result = findHardcodedStrings("return 'Required';");
      expect(result, isNotEmpty);
    });

    test('flags title with interpolation and text', () {
      final result = findHardcodedStrings("title: '\$count players'");
      expect(result, isNotEmpty);
    });

    test('flags multiline named argument', () {
      final result = findHardcodedStrings("title:\n    'Save'");
      expect(result, isNotEmpty);
    });

    test('flags TextSpan with text', () {
      final result = findHardcodedStrings("TextSpan(text: 'Hi')");
      expect(result, isNotEmpty);
    });

    test('does not flag l10n reference', () {
      final result = findHardcodedStrings("Text(l10n.save)");
      expect(result, isEmpty);
    });

    test('does not flag AppStrings reference', () {
      final result = findHardcodedStrings("Text(AppStrings.foo)");
      expect(result, isEmpty);
    });

    test('does not flag pure interpolation', () {
      final result = findHardcodedStrings("Text('\$name')");
      expect(result, isEmpty);
    });

    test('does not flag complex interpolation', () {
      final result = findHardcodedStrings("Text('\${a.b}')");
      expect(result, isEmpty);
    });

    test('does not flag l10n in named argument', () {
      final result = findHardcodedStrings("title: context.l10n.x");
      expect(result, isEmpty);
    });

    test('does not flag l10n-ignore comment', () {
      final result = findHardcodedStrings("Text('Save') // l10n-ignore: brand");
      expect(result, isEmpty);
    });

    test('does not flag full-line comment', () {
      final result = findHardcodedStrings("// Text('x')");
      expect(result, isEmpty);
    });

    test('does not flag literal in block comment', () {
      final result = findHardcodedStrings("/* Text('x') */");
      expect(result, isEmpty);
    });

    test('does not flag Key(\'abc\')', () {
      final result = findHardcodedStrings("Key('abc')");
      expect(result, isEmpty);
    });

    test('does not flag Icons.add', () {
      final result = findHardcodedStrings("Icons.add");
      expect(result, isEmpty);
    });

    test('does not flag route path', () {
      final result = findHardcodedStrings("context.push('/games')");
      expect(result, isEmpty);
    });

    test('does not flag DateFormat pattern', () {
      final result = findHardcodedStrings("DateFormat('EEE, d MMM y')");
      expect(result, isEmpty);
    });

    test('does not flag asset path', () {
      final result = findHardcodedStrings("'assets/images/x.png'");
      expect(result, isEmpty);
    });
  });

  test('migrated files exist', () {
    final notFound = <String>[];
    for (final path in migratedPaths) {
      final files = _dartFiles(path).toList();
      if (files.isEmpty) {
        notFound.add(path);
      }
    }
    expect(notFound, isEmpty,
      reason: 'migratedPaths entries not found:\n${notFound.join('\n')}');
  });

  test('migrated files contain no hardcoded user-visible strings', () {
    final offenders = <String>[];
    var filesScanned = 0;

    for (final path in migratedPaths) {
      final files = _dartFiles(path).toList();
      if (files.isEmpty) {
        fail('migratedPaths entry not found: $path');
      }

      for (final file in files) {
        filesScanned++;
        final content = file.readAsStringSync();
        final found = findHardcodedStrings(content);
        for (final offender in found) {
          offenders.add('${file.path}: $offender');
        }
      }
    }

    if (filesScanned == 0) {
      fail('no files scanned from migratedPaths');
    }

    expect(offenders, isEmpty, reason: 'Hardcoded strings:\n${offenders.join('\n')}');
  });
}
