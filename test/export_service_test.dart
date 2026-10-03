import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/data/db/fts.dart';
import 'package:openscan/domain/entities/ocr_block.dart' as domain;
import 'package:openscan/domain/entities/ocr_box.dart';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/features/export/application/export_providers.dart';

void main() {
  test('exporta PDF e indexa OCR', () async {
    final dir = await Directory.systemTemp.createTemp('exp_test');
    addTearDown(() => dir.delete(recursive: true));
    final docs = Directory('${dir.path}/docs')..createSync();
    final db = AppDb.openFile(File('${dir.path}/t.db'), 'k');
    addTearDown(db.close);

    final image = img.Image(width: 20, height: 20);
    final jpgPath = '${dir.path}/p.jpg';
    await File(jpgPath).writeAsBytes(img.encodeJpg(image));

    const ocr = OcrResult(
      fullText: 'palabraexport',
      blocks: [
        domain.OcrBlock(
          text: 'palabraexport',
          box: OcrBox(x: 0, y: 0, w: 1, h: 0.2, conf: 1),
        ),
      ],
    );
    const page = ScannedPage(
      id: 'p1',
      imagePath: '',
      width: 20,
      height: 20,
    );
    final file = await const ExportService().exportBatch(
      db: db,
      docsDir: docs,
      pages: [
        ScannedPage(
          id: page.id,
          imagePath: jpgPath,
          width: 20,
          height: 20,
        ),
      ],
      ocrByPage: const {'p1': ocr},
      title: 'Prueba',
      now: DateTime(2026, 1, 2, 3, 4),
    );

    expect(file.path.endsWith('.pdf'), isTrue);
    expect(await searchDocuments(db, 'palabraexport'), hasLength(1));
    // Página copiada al sandbox propio (backup la cubre).
    final stored = Directory('${docs.path}/pages')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .toList();
    expect(stored, hasLength(1));
  });
}
