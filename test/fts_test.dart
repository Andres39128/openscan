import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/data/db/fts.dart';

/// Inserta un documento con un bloque de texto.
Future<void> _docWithText(AppDb db, String id, String text) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await db.into(db.documents).insert(
        DocumentsCompanion.insert(
          id: id,
          title: 'Doc $id',
          createdAt: now,
          updatedAt: now,
        ),
      );
  await db.into(db.pages).insert(
        PagesCompanion.insert(
          id: '${id}_p0',
          docId: id,
          path: '/tmp/$id.jpg',
          width: 10,
          height: 10,
          position: 0,
        ),
      );
  await db.into(db.ocrBlocks).insert(
        OcrBlocksCompanion.insert(
          pageId: '${id}_p0',
          content: text,
          x: 0,
          y: 0,
          w: 1,
          h: 1,
          conf: 1,
        ),
      );
}

void main() {
  test('sanitiza query con comillas FTS5', () {
    expect(buildMatchQuery('factura edesur'), '"factura" "edesur"');
    expect(buildMatchQuery('  '), '""');
    expect(buildMatchQuery('a"b'), '"a""b"');
  });

  test('búsqueda encuentra por palabra indexada', () async {
    final dir = await Directory.systemTemp.createTemp('fts_test');
    final db = AppDb.openFile(File('${dir.path}/t.db'), 'k');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    await _docWithText(db, 'd1', 'Factura Edesur enero');
    await _docWithText(db, 'd2', 'Contrato alquiler');

    final hits = await searchDocuments(db, 'edesur');
    expect(hits.map((d) => d.id), ['d1']);
    expect(await searchDocuments(db, 'inexistente'), isEmpty);
  });

  test('500 docs: búsqueda en orden de magnitud (<2s en CI)', () async {
    final dir = await Directory.systemTemp.createTemp('fts_perf');
    final db = AppDb.openFile(File('${dir.path}/t.db'), 'k');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    for (var i = 0; i < 500; i++) {
      await _docWithText(db, 'd$i', 'factura comun numero $i');
    }
    await _docWithText(db, 'target', 'palabra rara zzzqqq');

    final sw = Stopwatch()..start();
    final hits = await searchDocuments(db, 'zzzqqq');
    sw.stop();

    expect(hits.map((d) => d.id), ['target']);
    // DoD prod <200ms en dispositivo; en CI se verifica orden de magnitud.
    expect(sw.elapsedMilliseconds, lessThan(2000));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
