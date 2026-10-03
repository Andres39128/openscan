import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/core/image/decode.dart';
import 'package:openscan/core/pdf/searchable_pdf.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/core/text/slugify.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/domain/repositories/ocr_engine.dart';
import 'package:openscan/features/ocr/application/ocr_providers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Orquesta export: OCR → PDF searchable → guarda + indexa → comparte.
/// Indexa en `ocr_blocks` (los triggers FTS hacen el resto).
class ExportService {
  /// Crea el servicio sobre el motor OCR activo.
  const new(this._ocr);

  final OcrEngine _ocr;

  /// Exporta el batch y devuelve el PDF. Lanza [AppFailure] en error.
  Future<File> exportBatch({
    required AppDb db,
    required List<ScannedPage> pages,
    required String title,
    required DateTime now,
  }) async {
    final epoch = now.millisecondsSinceEpoch ~/ 1000;
    final docId = 'doc_$epoch';
    await db.into(db.documents).insert(
          DocumentsCompanion.insert(
            id: docId,
            title: title,
            createdAt: epoch,
            updatedAt: epoch,
          ),
        );

    final docsDir = await getApplicationDocumentsDirectory();
    final pagesDir = Directory('${docsDir.path}/pages');
    await pagesDir.create(recursive: true);

    final inputs = <SearchablePage>[];
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageId = '${docId}_p$i';
      // Copia a sandbox propio: el backup cubre docs/ completo.
      final storedPath = '${pagesDir.path}/$pageId.jpg';
      final bytes = await File(page.imagePath).readAsBytes();
      await File(storedPath).writeAsBytes(bytes, flush: true);
      final size = await decodeSize(bytes);
      final ocr = await _ocr.recognize(bytes);
      inputs.add(
        SearchablePage(
          jpeg: bytes,
          widthPt: size.width.toDouble(),
          heightPt: size.height.toDouble(),
          ocr: ocr,
        ),
      );
      await db.into(db.pages).insert(
            PagesCompanion.insert(
              id: pageId,
              docId: docId,
              path: storedPath,
              width: size.width,
              height: size.height,
              position: i,
            ),
          );
      for (final b in ocr.blocks) {
        await db.into(db.ocrBlocks).insert(
              OcrBlocksCompanion.insert(
                pageId: pageId,
                content: b.text,
                x: b.box.x,
                y: b.box.y,
                w: b.box.w,
                h: b.box.h,
                conf: b.box.conf,
              ),
            );
      }
    }
    await (db.update(db.documents)..where((t) => t.id.equals(docId))).write(
      DocumentsCompanion(pageCount: Value(pages.length)),
    );

    final pdfBytes = await buildSearchablePdf(inputs);
    final out = File(p.join(docsDir.path, exportFileName(title, now)));
    await out.writeAsBytes(pdfBytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(out.path)], text: title),
    );
    return out;
  }
}

/// Servicio de exportación activo.
final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.watch(ocrEngineProvider)),
);
