import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files/directories (relative to `frontend/`) whose user-visible text must
/// come from AppLocalizations. Migration tasks append to this list.
const List<String> migratedPaths = <String>[
  'lib/features/profile/presentation/widgets/language_sheet.dart',
];

final List<RegExp> _patterns = <RegExp>[
  // Text('Foo'), Text("Foo"), Text(const 'Foo')
  RegExp(r'''Text\(\s*(const\s+)?['"][^'"]*[A-Za-z֐-׿]'''),
  // labelText: 'Foo', hintText: 'Foo', title: 'Foo', content: Text('Foo') etc.
  RegExp(
    r'''\b(labelText|hintText|helperText|errorText|tooltip|semanticLabel|label|title|subtitle|content|message)\s*:\s*(const\s+)?['"][^'"$]*[A-Za-z֐-׿]''',
  ),
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

void main() {
  test('migrated files contain no hardcoded user-visible strings', () {
    final offenders = <String>[];
    for (final path in migratedPaths) {
      for (final file in _dartFiles(path)) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('l10n-ignore')) continue;
          if (line.trimLeft().startsWith('//')) continue;
          if (_patterns.any((p) => p.hasMatch(line))) {
            offenders.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Hardcoded strings:\n${offenders.join('\n')}');
  });
}
