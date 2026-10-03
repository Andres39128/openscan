import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/datasources/ocr_dto.dart';

/// Mock para dev/stg hasta F2 (bridges nativos reales).
class MockOcrDataSource implements OcrDataSource {
  /// Crea el mock de F1.
  const new();

  @override
  Future<OcrResultDto> recognizeText(
    String imagePath,
    List<String> langs,
  ) async =>
      const OcrResultDto(
        fullText: 'Factura mock',
        blocks: [
          OcrBlockDto(
            text: 'Factura mock',
            x: 0.1,
            y: 0.1,
            w: 0.8,
            h: 0.1,
            conf: 0.99,
          ),
        ],
      );
}
