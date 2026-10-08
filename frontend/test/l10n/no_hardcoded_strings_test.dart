import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files/directories (relative to `frontend/`) whose user-visible text must
/// come from AppLocalizations. Migration tasks append to this list.
const List<String> migratedPaths = <String>[
  'lib/features/profile/presentation/widgets/language_sheet.dart',
  'lib/features/auth/presentation',
  'lib/features/onboarding/presentation',
  'lib/shared/widgets',
  'lib/core/constants/skill_level_labels.dart',
  'lib/features/home',
  'lib/features/games/presentation',
  'lib/features/search/presentation',
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

/// Represents a string literal found in the source.
class StringLiteral {
  final String content; // The string literal value (without quotes)
  final int lineNumber; // 1-based line number where the literal starts
  final int endLine; // 1-based line number where the literal ends
  final String sourceLineText; // The source line text
  final int sourceStart; // Position in source where the literal starts
  final String source; // The full source for context
  final int endPos; // Position in source just after the closing quote

  StringLiteral(this.content, this.lineNumber, this.endLine, this.sourceLineText, this.sourceStart, this.source, this.endPos);
}

/// Removes interpolation (${...} and $ident) from a string literal.
String _removeInterpolation(String literal) {
  var result = literal.replaceAll(RegExp(r'\$\{[^}]*\}'), '');
  result = result.replaceAll(RegExp(r'\$\w+'), '');
  return result;
}

/// Checks if a string (after interpolation removal) contains letters.
bool _hasLetters(String str) {
  return RegExp(r'[A-Za-z֐-׿]').hasMatch(str);
}

/// Tokenizes the source code and extracts string literals.
/// Handles comments, strings, interpolation, raw strings, and triple-quoted strings.
List<StringLiteral> _tokenizeAndExtractStrings(String source) {
  final literals = <StringLiteral>[];
  var i = 0;
  var lineNumber = 1;
  final lines = source.split('\n');

  // Helper to get the text of a line by line number
  String getLineText(int line) {
    return line > 0 && line <= lines.length ? lines[line - 1] : '';
  }

  while (i < source.length) {
    // Track line numbers
    if (source[i] == '\n') {
      lineNumber++;
      i++;
      continue;
    }

    // Handle line comments
    if (i + 1 < source.length && source[i] == '/' && source[i + 1] == '/') {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
      continue;
    }

    // Handle block comments
    if (i + 1 < source.length && source[i] == '/' && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < source.length) {
        if (source[i] == '\n') lineNumber++;
        if (source[i] == '*' && source[i + 1] == '/') {
          i += 2;
          break;
        }
        i++;
      }
      continue;
    }

    // Handle raw strings: r'...' or r"..."
    if (source[i] == 'r' && i + 1 < source.length && (source[i + 1] == '"' || source[i + 1] == "'")) {
      final quote = source[i + 1];
      final startLine = lineNumber;
      final startPos = i;
      i += 2;
      var content = '';

      // Check for triple quotes
      final isTriple = i + 1 < source.length && source[i] == quote && source[i + 1] == quote;
      if (isTriple) {
        i += 2;
        while (i + 2 < source.length) {
          if (source[i] == quote && source[i + 1] == quote && source[i + 2] == quote) {
            i += 3;
            break;
          }
          if (source[i] == '\n') lineNumber++;
          content += source[i];
          i++;
        }
      } else {
        while (i < source.length && source[i] != quote) {
          if (source[i] == '\n') lineNumber++;
          content += source[i];
          i++;
        }
        if (i < source.length && source[i] == quote) i++;
      }

      literals.add(StringLiteral(content, startLine, lineNumber, getLineText(startLine), startPos, source, i));
      continue;
    }

    // Handle regular strings: '...' or "..."
    if (source[i] == '"' || source[i] == "'") {
      final quote = source[i];
      final startLine = lineNumber;
      final startPos = i;
      i++;
      var content = '';

      // Check for triple quotes
      final isTriple = i + 1 < source.length && source[i] == quote && source[i + 1] == quote;
      if (isTriple) {
        i += 2;
        while (i + 2 < source.length) {
          if (source[i] == quote && source[i + 1] == quote && source[i + 2] == quote) {
            i += 3;
            break;
          }
          if (source[i] == '\n') lineNumber++;
          if (source[i] == '\\' && i + 1 < source.length) {
            i++;
            if (source[i] == '\n') lineNumber++;
            content += source[i];
            i++;
          } else if (source[i] == '\$' && i + 1 < source.length) {
            if (source[i + 1] == '{') {
              content += r'${...}';
              i += 2;
              var braces = 1;
              while (i < source.length && braces > 0) {
                if (source[i] == '{') braces++;
                if (source[i] == '}') braces--;
                if (source[i] == '\n') lineNumber++;
                i++;
              }
            } else if (_isIdentStart(source[i + 1])) {
              content += r'$';
              i++;
              while (i < source.length && _isIdentChar(source[i])) {
                i++;
              }
            } else {
              content += source[i];
              i++;
            }
          } else {
            content += source[i];
            i++;
          }
        }
      } else {
        // Regular string
        while (i < source.length && source[i] != quote) {
          if (source[i] == '\n') lineNumber++;
          if (source[i] == '\\' && i + 1 < source.length) {
            i++;
            if (source[i] == '\n') lineNumber++;
            content += source[i];
            i++;
          } else if (source[i] == '\$' && i + 1 < source.length) {
            if (source[i + 1] == '{') {
              content += r'${...}';
              i += 2;
              var braces = 1;
              while (i < source.length && braces > 0) {
                if (source[i] == '{') braces++;
                if (source[i] == '}') braces--;
                if (source[i] == '\n') lineNumber++;
                i++;
              }
            } else if (_isIdentStart(source[i + 1])) {
              content += r'$';
              i++;
              while (i < source.length && _isIdentChar(source[i])) {
                i++;
              }
            } else {
              content += source[i];
              i++;
            }
          } else {
            content += source[i];
            i++;
          }
        }
        if (i < source.length && source[i] == quote) i++;
      }

      literals.add(StringLiteral(content, startLine, lineNumber, getLineText(startLine), startPos, source, i));
      continue;
    }

    i++;
  }

  return literals;
}

bool _isIdentStart(String char) {
  return RegExp(r'[a-zA-Z_]').hasMatch(char);
}

bool _isIdentChar(String char) {
  return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
}

/// Checks if a string literal is in a non-UI context and should be skipped.
bool _isNonUiContext(String codeBefore, String literal) {
  // Check for import/export/part directives
  if (RegExp(r'(^|[;\n])\s*(import|export|part|library)\b[^;]*$').hasMatch(codeBefore)) {
    return true;
  }

  // Check for case labels: 'case' keyword before the literal
  if (RegExp(r'\bcase\s*$').hasMatch(codeBefore)) {
    return true;
  }

  // Font family names (fontFamilyFallback: ['Heebo'] etc.) are not UI text.
  if (RegExp(r'fontFamilyFallback:\s*(const\s*)?\[[^\]]*$').hasMatch(codeBefore)) {
    return true;
  }

  // Equality comparisons against a literal are logic, not UI.
  if (RegExp(r'[=!]=\s*$').hasMatch(codeBefore)) {
    return true;
  }

  // Check for specific non-UI callees and constructors
  final nonUiCallees = [
    'Key(',
    'ValueKey(',
    'ValueKey<String>(',
    'PageStorageKey(',
    'GlobalKey(',
    'Locale(',
    'DateFormat(',
    'NumberFormat(',
    'RegExp(',
    'Uri.parse(',
    'Exception(',
    'Error(',
    'StateError(',
    'ArgumentError(',
    'print(',
    'debugPrint(',
    'log(',
    '.push(',
    '.go(',
    '.pushNamed(',
    '.goNamed(',
    '.replace(',
    '.pushReplacement(',
    '.getString(',
    '.setString(',
    '.getBool(',
    '.setBool(',
    '.getInt(',
    '.setInt(',
    '.remove(',
    '.containsKey(',
    '.fromEnvironment(',
    'Hero(tag:',
    'heroTag:',
    'fontFamily:',
    'package:',
    'tag:',
    'restorationId:',
  ];

  for (final callee in nonUiCallees) {
    if (!codeBefore.endsWith(callee)) continue;
    final before = codeBefore.length > callee.length
        ? codeBefore[codeBefore.length - callee.length - 1]
        : '';
    final needsBoundary = RegExp(r'^[A-Za-z]').hasMatch(callee);
    if (needsBoundary && RegExp(r'[A-Za-z0-9_$]').hasMatch(before)) continue;
    return true;
  }

  // Check for map-index access: identifier or ] before [
  if (RegExp(r'[\w\])]\s*\[\s*$').hasMatch(codeBefore)) {
    return true;
  }

  // Check for path-like strings: no spaces, contains / or ., no Hebrew
  if (!literal.contains(' ') && (literal.contains('/') || literal.contains('.'))) {
    if (!RegExp(r'[֐-׿]').hasMatch(literal)) {
      return true;
    }
  }

  return false;
}

/// Extracts hardcoded string literals from Dart source code.
/// Returns a list of offenders in the format "line N: <text>".
List<String> findHardcodedStrings(String source) {
  final offenders = <String>[];
  final literals = _tokenizeAndExtractStrings(source);

  // A trailing marker covers its own line; a marker on a comment-only line
  // also covers the line directly below it.
  final lines = source.split('\n');
  final ignoreLinesSet = <int>{};
  for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
    final lineNum = lineIdx + 1;
    final text = lines[lineIdx];
    if (!text.contains('l10n-ignore')) continue;
    ignoreLinesSet.add(lineNum);
    if (text.trimLeft().startsWith('//')) ignoreLinesSet.add(lineNum + 1);
  }

  for (final lit in literals) {
    // A marker on any line the literal spans covers it.
    var ignored = false;
    for (var l = lit.lineNumber; l <= lit.endLine; l++) {
      if (ignoreLinesSet.contains(l)) ignored = true;
    }
    if (ignored) continue;

    // Remove interpolation and check for letters
    final noInterp = _removeInterpolation(lit.content);
    if (noInterp.isEmpty || !_hasLetters(noInterp)) {
      continue;
    }

    // Extract code before the literal (up to 200 chars back, excluding comments)
    final codeBeforeStart = lit.sourceStart > 200 ? lit.sourceStart - 200 : 0;
    var codeBefore = lit.source.substring(codeBeforeStart, lit.sourceStart);

    // Remove comments from codeBefore (// and /* */)
    codeBefore = codeBefore.replaceAll(RegExp(r'//.*'), '');
    codeBefore = codeBefore.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Keep only the last 60 chars for pattern matching
    if (codeBefore.length > 60) {
      codeBefore = codeBefore.substring(codeBefore.length - 60);
    }
    codeBefore = codeBefore.trim();

    // Map keys ({'title': x, 'sport': y}) are API field names, not UI text.
    // A ternary's middle branch (cond ? 'a' : 'b') is preceded by `?`, not `{` or `,`.
    if (RegExp(r'[{,)]$').hasMatch(codeBefore) &&
        RegExp(r'^\s*:').hasMatch(lit.source.substring(lit.endPos))) {
      continue;
    }

    // Check if this is a non-UI context
    if (_isNonUiContext(codeBefore, noInterp)) {
      continue;
    }

    // This is an offender
    offenders.add('line ${lit.lineNumber}: ${lit.sourceLineText.trim()}');
  }

  // Remove duplicates and sort
  int lineOf(String o) => int.parse(RegExp(r'^line (\d+)').firstMatch(o)!.group(1)!);
  return offenders.toSet().toList()
    ..sort((a, b) {
      final c = lineOf(a).compareTo(lineOf(b));
      return c != 0 ? c : a.compareTo(b);
    });
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

    test('flags \'?\' ternary regression with real text after', () {
      final result = findHardcodedStrings("final c = x ? '?' : null; Text('Hello')");
      expect(result, isNotEmpty);
      expect(result.length, 1); // Only one offender
      expect(result[0], contains('Hello'));
    });

    test('flags tuple/record with literals', () {
      final result = findHardcodedStrings("'open' => (AppColors.statusOpen, 'Open')");
      expect(result, isNotEmpty);
    });

    test('flags helper call with literal argument', () {
      final result = findHardcodedStrings("_row('Label here')");
      expect(result, isNotEmpty);
    });

    test('flags else branch with literal', () {
      final result = findHardcodedStrings("Text(x ? a : 'Off')");
      expect(result, isNotEmpty);
    });

    test('flags triple-quoted multi-line string', () {
      final result = findHardcodedStrings("final s = '''Multi\nline\ntext with letters''';");
      expect(result, isNotEmpty);
      expect(result[0], contains('line 1')); // Reported at start line
    });

    test('flags raw string', () {
      final result = findHardcodedStrings("Text(r'Hello')");
      expect(result, isNotEmpty);
    });

    test('flags description named argument', () {
      final result = findHardcodedStrings("description: 'x y'");
      expect(result, isNotEmpty);
    });

    test('flags prefixText argument', () {
      final result = findHardcodedStrings("prefixText: 'US'");
      expect(result, isNotEmpty);
    });

    test('flags Hebrew text', () {
      final result = findHardcodedStrings("Text('שלום')");
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
      final result = findHardcodedStrings("Text('\${a[\"b\"]}')");
      expect(result, isEmpty);
    });

    test('does not flag l10n in named argument', () {
      final result = findHardcodedStrings("title: context.l10n.x");
      expect(result, isEmpty);
    });

    test('does not flag l10n-ignore comment on same line', () {
      final result = findHardcodedStrings("Text('Save') // l10n-ignore: brand");
      expect(result, isEmpty);
    });

    test('does not flag l10n-ignore marker on line above', () {
      final result = findHardcodedStrings("// l10n-ignore: brand\nText('Save')");
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

    test('does not flag ValueKey with spaces', () {
      final result = findHardcodedStrings("ValueKey('a b')");
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

    test('does not flag dynamic route path', () {
      final result = findHardcodedStrings("context.go(\"/chat/\$id\")");
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

    test('does not flag url inside comment', () {
      final result = findHardcodedStrings("// See https://x.y/z");
      expect(result, isEmpty);
    });

    test('flags string with spaces containing //', () {
      final result = findHardcodedStrings('final u = "a//b c";');
      expect(result, isNotEmpty);
    });

    test('handles url in string with l10n-ignore marker', () {
      final result = findHardcodedStrings("final s = 'http://x.y/z'; // l10n-ignore: url");
      expect(result, isEmpty);
    });

    test('does not flag json map access', () {
      final result = findHardcodedStrings("json['userName']");
      expect(result, isEmpty);
    });

    test('does not flag map access', () {
      final result = findHardcodedStrings("map[\"k\"]");
      expect(result, isEmpty);
    });

    test('block comment spanning lines before offender reports correct line', () {
      const source = '''
/* multi
   line
   comment */
Text('Hi')
''';
      final result = findHardcodedStrings(source);
      expect(result, isNotEmpty);
      expect(result[0], contains('line 4'));
    });

    // H1: l10n-ignore marker leaks
    test('H1.1: trailing marker covers only its line, not next', () {
      final result = findHardcodedStrings("Text('Save') // l10n-ignore: brand\nText('Leaked')");
      expect(result, hasLength(1), reason: 'should flag only Leaked');
      expect(result[0], contains('line 2'));
    });

    test('H1.2: comment-only marker above covers literal below', () {
      final result = findHardcodedStrings("// l10n-ignore: brand\nText('Saved')");
      expect(result, isEmpty, reason: 'marker-only line above should cover literal below');
    });

    test('H1.3: comment-only marker above does NOT cover two lines below', () {
      final result = findHardcodedStrings("// l10n-ignore: brand\n\nText('NotCovered')");
      expect(result, isNotEmpty, reason: 'marker should not skip blank line to literal');
    });

    test('H1.4: multi-line string with marker on end line is covered', () {
      final result = findHardcodedStrings("final s = '''Multi\nline\ntext'''; // l10n-ignore");
      expect(result, isEmpty, reason: 'marker on end line of multi-line string should cover it');
    });

    // H2: import|export|part|library check anchoring
    test('H2.1: import directive not flagged', () {
      final result = findHardcodedStrings("import 'package:flutter/material.dart';");
      expect(result, isEmpty);
    });

    test('H2.2: export directive not flagged', () {
      final result = findHardcodedStrings("export 'a.dart' show X;");
      expect(result, isEmpty);
    });

    test('H2.3: part directive not flagged', () {
      final result = findHardcodedStrings("part 'x.g.dart';");
      expect(result, isEmpty);
    });

    test('H2.4: Text after export keyword IS flagged', () {
      final result = findHardcodedStrings("Text('Tap to export'), Text('Hello')");
      expect(result, isNotEmpty, reason: 'Hello is not in directive');
      expect(result.any((s) => s.contains('Hello')), isTrue);
    });

    test('H2.5: part as variable does NOT suppress Text', () {
      final result = findHardcodedStrings("final part = 1; Text(part ? 'Hello world' : null)");
      expect(result, isNotEmpty, reason: 'part is a variable, not directive');
      expect(result[0], contains('Hello world'));
    });

    // M1: Callee deny-list word boundary
    test('M1.1: dialog( should flag, not suppress like log(', () {
      final result = findHardcodedStrings("dialog('Hello there')");
      expect(result, isNotEmpty, reason: 'dialog is not a non-UI callee');
    });

    test('M1.2: log( should not flag', () {
      final result = findHardcodedStrings("log('x y z')");
      expect(result, isEmpty);
    });

    // M2: fontFamilyFallback list skip
    test('M2: fontFamilyFallback const list not flagged', () {
      final result = findHardcodedStrings("fontFamilyFallback: const ['Heebo']");
      expect(result, isEmpty);
    });

    // M3: Equality comparison skip
    test('M3.1: equality comparison not flagged', () {
      final result = findHardcodedStrings("if (status == 'open') {}");
      expect(result, isEmpty);
    });

    test('M3.2: Text(\'open\') still flags even with open elsewhere', () {
      final result = findHardcodedStrings("if (x == 'open') Text('open')");
      expect(result, isNotEmpty, reason: 'Text with open should flag');
    });

    // M4: Backslash-escaped newline line counter
    test('M4: backslash-escaped newline increments line counter', () {
      const source = "final s = 'line\\\nnewline'; Text('Hello')";
      final result = findHardcodedStrings(source);
      // The first literal is also flagged (line 1); Hello must be on line 2.
      expect(result.any((r) => r.startsWith('line 2') && r.contains('Hello')), isTrue);
    });

    test('map keys are not flagged', () {
      final result = findHardcodedStrings("final m = {'title': t, 'sport': s};");
      expect(result, isEmpty);
    });

    test('map keys on separate lines are not flagged', () {
      final result =
          findHardcodedStrings("final m = {\n  'title': t,\n  'maxPlayers': 3,\n};");
      expect(result, isEmpty);
    });

    test('conditional map entries are not flagged', () {
      final result = findHardcodedStrings("final m = {if (ok) 'title': t};");
      expect(result, isEmpty);
    });

    test('ternary middle branch is still flagged', () {
      final result = findHardcodedStrings("Text(a ? 'Open' : 'Closed')");
      expect(result, isNotEmpty);
    });

    test('map value literal is still flagged', () {
      final result = findHardcodedStrings("final m = {'label': 'Hello there'};");
      expect(result, isNotEmpty);
    });

    // Interpolation placeholders contain dots and must not look like paths.
    test('interpolated text without spaces is still flagged', () {
      final result = findHardcodedStrings("Text('\${count}d')");
      expect(result, isNotEmpty);
    });

    // M5: Numeric line sorting
    test('M5: offenders sorted numerically by line', () {
      const source = "Text('Line27')\nText('Line127')";
      final result = findHardcodedStrings(source);
      expect(result, hasLength(2));
      // Extract line numbers
      final line1 = int.parse(RegExp(r'line (\d+)').firstMatch(result[0])!.group(1)!);
      final line2 = int.parse(RegExp(r'line (\d+)').firstMatch(result[1])!.group(1)!);
      expect(line1, lessThan(line2), reason: 'should be sorted by line number');
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

    expect(offenders, isEmpty,
        reason: 'Hardcoded strings:\n${offenders.join('\n')}');
  });
}
