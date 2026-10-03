import 'dart:typed_data';
import 'package:openscan/domain/entities/ocr_result.dart';

/// Puerto OCR offline (ARCHITECTURE §5). Vision / ML Kit detrás.
abstract class OcrEngine {
  /// Reconoce texto en [imageBytes]. `langs` por defecto ES+EN (PLAN §2).
  Future<OcrResult> recognize(
    Uint8List imageBytes, {
    List<String> langs = const ['es', 'en'],
  });
}
