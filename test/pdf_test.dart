import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/pdf/searchable_pdf.dart';
import 'package:openscan/domain/entities/ocr_block.dart';
import 'package:openscan/domain/entities/ocr_box.dart';
import 'package:openscan/domain/entities/ocr_result.dart';

/// Extrae el texto de los streams comprimidos del PDF.
String _visibleText(Uint8List pdf) {
  final raw = String.fromCharCodes(pdf);
  final out = StringBuffer();
  var i = 0;
  while (true) {
    final s = raw.indexOf('stream\n', i);
    if (s < 0) break;
    final e = raw.indexOf('endstream', s);
    if (e < 0) break;
    final bytes = Uint8List.fromList(raw.substring(s + 7, e).codeUnits);
    try {
      out.write(String.fromCharCodes(ZLibCodec().decode(bytes)));
    } on Object catch (_) {
      // Stream no comprimido: se ignora.
    }
    i = e + 9;
  }
  return out.toString();
}

void main() {
  test('PDF con capa de texto buscable', () async {
    final image = img.Image(width: 100, height: 100);
    final bytes = await buildSearchablePdf([
      SearchablePage(
        jpeg: img.encodeJpg(image),
        widthPt: 100,
        heightPt: 100,
        ocr: const OcrResult(
          fullText: 'Hola Mundo',
          blocks: [
            OcrBlock(
              text: 'Hola',
              box: OcrBox(x: 0.1, y: 0.1, w: 0.5, h: 0.1, conf: 1),
            ),
          ],
        ),
      ),
    ]);

    expect(bytes.isNotEmpty, isTrue);
    // Streams FlateDecode inflados: el texto debe estar buscable.
    expect(_visibleText(bytes), contains('Hola'));
  });
}
