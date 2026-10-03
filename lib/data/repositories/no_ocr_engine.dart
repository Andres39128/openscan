import 'dart:typed_data';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:openscan/domain/repositories/ocr_engine.dart';

/// Variante F-Droid: sin motor OCR (Tesseract en v2).
/// Resultado vacío válido: PDF solo-imagen, búsqueda sin índice.
class NoOcrEngine implements OcrEngine {
  /// Crea el motor vacío.
  const new();

  @override
  Future<OcrResult> recognize(
    Uint8List imageBytes, {
    List<String> langs = const ['es', 'en'],
  }) async =>
      const OcrResult(fullText: '', blocks: []);
}
