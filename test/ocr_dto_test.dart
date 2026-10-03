import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/data/datasources/ocr_dto.dart';

void main() {
  test('parsea el mapa del bridge nativo', () {
    final dto = OcrResultDto.fromMap(const {
      'fullText': 'Factura Edesur',
      'blocks': [
        {
          'text': 'Factura',
          'x': 0.1,
          'y': 0.2,
          'w': 0.3,
          'h': 0.05,
          'conf': 0.9,
        },
        {
          'text': 'Edesur',
          'x': 0.5,
          'y': 0.2,
          'w': 0.3,
          'h': 0.05,
          'conf': 0.4,
        },
      ],
    });

    expect(dto.fullText, 'Factura Edesur');
    expect(dto.blocks, hasLength(2));
    expect(dto.blocks[1].conf, 0.4);
  });
}
