import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/domain/entities/ocr_result.dart';

/// OCR por página ya reconocido (clave = page.id).
/// El OCR es explícito: lo dispara el usuario, nunca el export a escondidas.
class OcrResultsNotifier extends Notifier<Map<String, OcrResult>> {
  /// Estado inicial: nada reconocido.
  @override
  Map<String, OcrResult> build() => const {};

  /// Guarda el OCR de una página.
  void put(String pageId, OcrResult result) =>
      state = {...state, pageId: result};

  /// Limpia todo (nuevo batch).
  void clear() => state = const {};
}

/// Cache de OCR del batch actual.
final ocrResultsProvider =
    NotifierProvider<OcrResultsNotifier, Map<String, OcrResult>>(
  OcrResultsNotifier.new,
);
