import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/features/export/application/backup_service.dart';

void main() {
  test('roundtrip: exporta y restaura idéntico', () async {
    final src = await Directory.systemTemp.createTemp('bk_src');
    final out = await Directory.systemTemp.createTemp('bk_out');
    final dst = await Directory.systemTemp.createTemp('bk_dst');
    addTearDown(() async {
      await src.delete(recursive: true);
      await out.delete(recursive: true);
      await dst.delete(recursive: true);
    });
    await File('${src.path}/a.txt').writeAsString('hola');
    await Directory('${src.path}/sub').create();
    await File('${src.path}/sub/b.bin').writeAsBytes([0, 1, 2, 250]);

    const svc = BackupService();
    final enc = await svc.exportBackup(
      sourceDir: src,
      password: 'correcta-123',
      outDir: out,
    );
    expect(enc.path.endsWith('.enc'), isTrue);

    final n = await svc.restoreBackup(
      backup: enc,
      password: 'correcta-123',
      targetDir: dst,
    );
    expect(n, 2);
    expect(await File('${dst.path}/a.txt').readAsString(), 'hola');
    expect(await File('${dst.path}/sub/b.bin').readAsBytes(), [0, 1, 2, 250]);
  });

  test('password mal lanza BackupFailed', () async {
    final src = await Directory.systemTemp.createTemp('bk_src2');
    final out = await Directory.systemTemp.createTemp('bk_out2');
    addTearDown(() async {
      await src.delete(recursive: true);
      await out.delete(recursive: true);
    });
    await File('${src.path}/a.txt').writeAsString('x');

    const svc = BackupService();
    final enc = await svc.exportBackup(
      sourceDir: src,
      password: 'buena',
      outDir: out,
    );
    expect(
      svc.restoreBackup(backup: enc, password: 'mala', targetDir: out),
      throwsA(isA<BackupFailed>()),
    );
  });

  test('archivo truncado lanza BackupFailed', () async {
    final dir = await Directory.systemTemp.createTemp('bk_t');
    addTearDown(() => dir.delete(recursive: true));
    final bad = File('${dir.path}/bad.enc');
    await bad.writeAsBytes([1, 2, 3]);

    expect(
      const BackupService().restoreBackup(
        backup: bad,
        password: 'x',
        targetDir: dir,
      ),
      throwsA(isA<BackupFailed>()),
    );
  });
}
