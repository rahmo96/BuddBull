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

/// Represents a string literal found in the source.
class StringLiteral {
  final String content; // The string literal value (without quotes)
  final int lineNumber; // 1-based line number where the literal starts
  final String sourceLineText; // The source line text
  final int sourceStart; // Position in source where the literal starts
  final String source; // The full source for context

  StringLiteral(this.content, this.lineNumber, this.sourceLineText, this.sourceStart, this.source);
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

      literals.add(StringLiteral(content, startLine, getLineText(startLine), startPos, source));
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

      literals.add(StringLiteral(content, startLine, getLineText(startLine), startPos, source));
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
  if (RegExp(r'\b(import|export|part|library)\b').hasMatch(codeBefore)) {
    return true;
  }

  // Check for case labels: 'case' keyword before the literal
  if (RegExp(r'\bcase\s*$').hasMatch(codeBefore)) {
    return true;
  }

  // Check for specific non-UI callees and constructors
  final nonUiCallees = [
    'Key(',
    'ValueKey(',
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
    if (codeBefore.endsWith(callee)) {
      return true;
    }
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

  // Build a map of l10n-ignore markers by line
  final lines = source.split('\n');
  final ignoreLinesSet = <int>{};
  for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
    final lineNum = lineIdx + 1;
    if (lines[lineIdx].contains('l10n-ignore')) {
      ignoreLinesSet.add(lineNum);
      // Also mark the next line (if the marker is on the line above the literal)
      if (lineIdx + 1 < lines.length) {
        ignoreLinesSet.add(lineNum + 1);
      }
    }
  }

  for (final lit in literals) {
    // Check l10n-ignore marker on the same line or line above
    if (ignoreLinesSet.contains(lit.lineNumber)) {
      continue;
    }

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

    // Check if this is a non-UI context
    if (_isNonUiContext(codeBefore, lit.content)) {
      continue;
    }

    // This is an offender
    offenders.add('line ${lit.lineNumber}: ${lit.sourceLineText.trim()}');
  }

  // Remove duplicates and sort
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
