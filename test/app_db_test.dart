import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/data/db/app_db.dart';

void main() {
  // En VM se usa el sqlite del sistema: valida schema y CRUD.
  // El cifrado real (PRAGMA key contra SQLCipher) se verifica en
  // dispositivo: abrir el .db con sqlite3 sin key debe fallar (RULES §3).
  test('CRUD documents + conteo', () async {
    final dir = await Directory.systemTemp.createTemp('openscan_test');
    final db = AppDb.openFile(File('${dir.path}/t.db'), 'test-key');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    await db.into(db.documents).insert(
          DocumentsCompanion.insert(
            id: 'd1',
            title: 'Factura',
            createdAt: 1,
            updatedAt: 1,
          ),
        );

    expect(await db.documentCount(), 1);
  });
}
