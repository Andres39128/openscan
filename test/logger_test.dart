import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/logging/app_logger.dart';

void main() {
  test('escribe y rota sin PII en el formato', () async {
    final dir = await Directory.systemTemp.createTemp('log_test');
    addTearDown(() => dir.delete(recursive: true));
    final logger = AppLogger(dir)..log('scan', 'ok');
    final files = logger.logFiles();
    expect(files, hasLength(1));
    final content = await files.single.readAsString();
    expect(content, contains('[scan] ok'));
    // Timestamp ISO al inicio.
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(content), isTrue);
  });
}
