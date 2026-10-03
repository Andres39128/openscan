import 'dart:math' as math;
import 'dart:typed_data';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Página para el PDF: imagen + OCR posicionado.
class SearchablePage {
  /// Crea una página (medidas en puntos PDF).
  const new({
    required this.jpeg,
    required this.widthPt,
    required this.heightPt,
    required this.ocr,
  });

  /// JPEG de la página.
  final Uint8List jpeg;

  /// Ancho en puntos.
  final double widthPt;

  /// Alto en puntos.
  final double heightPt;

  /// OCR con cajas normalizadas 0..1.
  final OcrResult ocr;
}

/// Genera PDF con imagen + capa de texto invisible buscable (PLAN §2).
/// Puro (sin IO): devuelve bytes.
Future<Uint8List> buildSearchablePdf(List<SearchablePage> pages) {
  final doc = pw.Document();
  for (final page in pages) {
    final image = pw.MemoryImage(page.jpeg);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(page.widthPt, page.heightPt),
        build: (context) => pw.Stack(
          children: [
            pw.SizedBox(
              width: page.widthPt,
              height: page.heightPt,
              child: pw.Image(image, fit: pw.BoxFit.fill),
            ),
            ...page.ocr.blocks.map(
              (b) => pw.Positioned(
                left: b.box.x * page.widthPt,
                top: b.box.y * page.heightPt,
                child: pw.Text(
                  b.text,
                  style: pw.TextStyle(
                    font: pw.Font.helvetica(),
                    fontSize: _fontSize(b.box.h * page.heightPt),
                    color: const PdfColor(0, 0, 0, 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}

/// Tamaño desde la altura de caja (cap-height ≈ 0.7em), acotado.
double _fontSize(double boxHeightPt) =>
    math.min(72, math.max(4, boxHeightPt / 0.7));
