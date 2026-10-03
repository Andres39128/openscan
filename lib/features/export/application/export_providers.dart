import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/core/image/decode.dart';
import 'package:openscan/core/pdf/searchable_pdf.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/core/text/slugify.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:path/path.dart' as p;

/// Orquesta export: PDF searchable → guarda + indexa. Sin share (lo hace UI).
/// El OCR viene ya reconocido (explícito, nunca a escondidas).
/// Sin OCR para una página: sale solo-imagen.
/// Indexa en `ocr_blocks` (los triggers FTS hacen el resto).
class ExportService {
  /// Crea el servicio.
  const new();

  /// Exporta el batch y devuelve el PDF. Lanza [AppFailure] en error.
  Future<File> exportBatch({
    required AppDb db,
    required Directory docsDir,
    required List<ScannedPage> pages,
    required Map<String, OcrResult> ocrByPage,
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
      final ocr =
          ocrByPage[page.id] ?? const OcrResult(fullText: '', blocks: []);
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

    late Uint8List pdfBytes;
    try {
      pdfBytes = await buildSearchablePdf(inputs);
    } on Object catch (_) {
      throw const PdfFailed();
    }
    final out = File(p.join(docsDir.path, exportFileName(title, now)));
    await out.writeAsBytes(pdfBytes, flush: true);
    return out;
  }
}

/// Servicio de exportación activo.
/// Servicio de exportación activo.
final exportServiceProvider = Provider<ExportService>(
  (ref) => const ExportService(),
);
