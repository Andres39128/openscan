import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/domain/entities/classification.dart';
import 'package:openscan/domain/entities/doc_filter.dart';
import 'package:openscan/domain/entities/doc_type.dart';
import 'package:openscan/domain/entities/ocr_block.dart';
import 'package:openscan/domain/entities/ocr_box.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:openscan/domain/entities/scanned_page.dart';

void main() {
  test('entities comparan por valor y exponen props', () {
    const box = OcrBox(x: 0.1, y: 0.2, w: 0.3, h: 0.4, conf: 0.9);
    expect(box.x, 0.1);
    expect(box, const OcrBox(x: 0.1, y: 0.2, w: 0.3, h: 0.4, conf: 0.9));
    expect(
      box,
      isNot(const OcrBox(x: 0, y: 0.2, w: 0.3, h: 0.4, conf: 0.9)),
    );

    const block = OcrBlock(text: 't', box: box);
    expect(block.text, 't');
    expect(
      const OcrResult(fullText: 't', blocks: [block]),
      const OcrResult(fullText: 't', blocks: [block]),
    );

    const page = ScannedPage(
      id: 'p',
      imagePath: 'p.jpg',
      width: 10,
      height: 20,
    );
    expect(page.position, 0);
    final moved = page.copyWith(position: 2);
    expect(moved.position, 2);
    expect(moved.id, 'p');

    const c = Classification(tipo: DocType.factura, conf: 0.8);
    expect(c.emisor, isNull);
    expect(
      const Classification(tipo: DocType.factura, emisor: 'E', conf: 0.8),
      isNot(c),
    );
  });

  test('props se evalúan en ambas direcciones', () {
    expect(const OcrPoint(0, 0), isNot(const OcrPoint(0, 1)));
    expect(
      const OcrQuad(
        topLeft: OcrPoint(0, 0),
        topRight: OcrPoint(1, 0),
        bottomRight: OcrPoint(1, 1),
        bottomLeft: OcrPoint(0, 1),
      ),
      isNot(
        const OcrQuad(
          topLeft: OcrPoint(0, 0),
          topRight: OcrPoint(1, 0),
          bottomRight: OcrPoint(1, 1),
          bottomLeft: OcrPoint(0, 0.5),
        ),
      ),
    );
    const box = OcrBox(x: 0, y: 0, w: 1, h: 1, conf: 1);
    expect(
      const OcrBlock(text: 'a', box: box),
      isNot(const OcrBlock(text: 'b', box: box)),
    );
    expect(
      const OcrResult(fullText: 'a', blocks: []),
      isNot(const OcrResult(fullText: 'b', blocks: [])),
    );
    const page = ScannedPage(
      id: 'p',
      imagePath: 'p.jpg',
      width: 1,
      height: 1,
    );
    expect(page.copyWith(), page);
    expect(page.copyWith(position: 9).position, 9);
  });

  test('conjuntos cerrados: valores esperados', () {
    expect(DocType.values, hasLength(6));
    expect(DocType.values, contains(DocType.otro));
    expect(DocFilter.values, hasLength(4));
    expect(
      const OcrQuad(
        topLeft: OcrPoint(0, 0),
        topRight: OcrPoint(1, 0),
        bottomRight: OcrPoint(1, 1),
        bottomLeft: OcrPoint(0, 1),
      ).topRight,
      const OcrPoint(1, 0),
    );
  });
}
