import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/data/datasources/method_channel_ocr_datasource.dart';
import 'package:openscan/data/datasources/ocr_dto.dart';
import 'package:openscan/domain/entities/ocr_result.dart' show OcrResult;

/// Fuente OCR nativa. Prod = MethodChannel (F2); dev/stg = mock (bootstrap).
/// Fuente OCR nativa. Prod = MethodChannel (F2); dev/stg = mock.
abstract class OcrDataSource {
  /// Devuelve el DTO crudo del bridge para mapear a [OcrResult].
  /// Devuelve el DTO crudo del bridge para mapear a `OcrResult`.
  Future<OcrResultDto> recognizeText(String imagePath, List<String> langs);
}

/// Instancia activa (sobrescrita por mocks según flavor).
/// Instancia activa (sobrescrita por mocks según flavor).
final ocrDataSourceProvider = Provider<OcrDataSource>(
  (ref) => const MethodChannelOcrDataSource(),
);
