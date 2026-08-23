import 'dart:io';

Never _usage(String message) {
  stderr.writeln(message);
  stderr.writeln(
    'Dùng: dart run AI/shared/skills/code-health/scripts/'
    'run_code_health.dart [diff|audit] [--files <file...>]',
  );
  exit(2);
}

String _repositoryRoot() {
  var directory = File.fromUri(Platform.script).parent;
  for (var index = 0; index < 5; index++) {
    directory = directory.parent;
  }
  return directory.path;
}

String _absolutePath(String root, String relativePath) {
  final platformPath = relativePath.replaceAll('/', Platform.pathSeparator);
  return '$root${Platform.pathSeparator}$platformPath';
}

Future<ProcessResult> _run(
  String executable,
  List<String> arguments,
  String workingDirectory,
) async {
  stdout.writeln('\n> $executable ${arguments.join(' ')}');
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: Platform.isWindows,
  );
  if ((result.stdout as String).isNotEmpty) stdout.write(result.stdout);
  if ((result.stderr as String).isNotEmpty) stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);
  return result;
}

Future<List<String>> _gitLines(
  String root,
  List<String> arguments,
) async {
  final result = await Process.run('git', arguments, workingDirectory: root);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return (result.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

Future<List<String>> _changedFiles(String root) async {
  final tracked = await _gitLines(
    root,
    ['diff', '--name-only', '--diff-filter=ACMR', 'HEAD', '--'],
  );
  final untracked = await _gitLines(
    root,
    ['ls-files', '--others', '--exclude-standard'],
  );
  return {...tracked, ...untracked}.toList()..sort();
}

List<String> _allDartFiles(String root) {
  final ignoredSegments = {
    '.dart_tool',
    '.git',
    'build',
    'coverage',
    'Pods',
  };
  return Directory(root)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where(
        (file) => !file.uri.pathSegments.any(ignoredSegments.contains),
      )
      .map((file) => file.path.substring(root.length + 1))
      .toList()
    ..sort();
}

List<String> _validatedFiles(String root, List<String> files) {
  final rootPrefix = '$root${Platform.pathSeparator}';
  return files
      .map((file) {
        final absolute = File(_absolutePath(root, file)).absolute.path;
        if (!absolute.startsWith(rootPrefix) || !File(absolute).existsSync()) {
          _usage('Không tìm thấy file trong repository: $file');
        }
        return absolute.substring(rootPrefix.length).replaceAll(
              Platform.pathSeparator,
              '/',
            );
      })
      .toSet()
      .toList()
    ..sort();
}

bool _hasDartTests(String root) {
  final testDirectory = Directory(_absolutePath(root, 'test'));
  return testDirectory.existsSync() &&
      testDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .any((file) => file.path.endsWith('_test.dart'));
}

Future<void> main(List<String> arguments) async {
  final root = _repositoryRoot();
  final mode = arguments.isEmpty ? 'diff' : arguments.first;
  if (mode != 'diff' && mode != 'audit') {
    _usage('Chế độ không hỗ trợ: $mode');
  }

  final remaining = arguments.isEmpty ? <String>[] : arguments.sublist(1);
  List<String>? requestedFiles;
  if (remaining.isNotEmpty) {
    if (mode == 'audit' ||
        remaining.first != '--files' ||
        remaining.length == 1) {
      _usage('Đối số không hợp lệ.');
    }
    requestedFiles = remaining.sublist(1);
  }

  final files = mode == 'audit'
      ? _allDartFiles(root)
      : _validatedFiles(root, requestedFiles ?? await _changedFiles(root));
  final dartFiles = files.where((file) => file.endsWith('.dart')).toList();
  if (dartFiles.isEmpty) {
    stdout.writeln('Không có file Dart cần kiểm tra.');
    return;
  }

  await _run(
    'dart',
    ['format', '--output=none', '--set-exit-if-changed', ...dartFiles],
    root,
  );

  final pubspec = File(_absolutePath(root, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    _usage('Repository không có pubspec.yaml.');
  }
  final usesFlutter = pubspec.readAsStringSync().contains('sdk: flutter');
  await _run(usesFlutter ? 'flutter' : 'dart', ['analyze'], root);

  if (_hasDartTests(root)) {
    await _run(usesFlutter ? 'flutter' : 'dart', ['test'], root);
  } else {
    stdout.writeln('Không tìm thấy test/*_test.dart; bỏ qua test runner.');
  }
}
