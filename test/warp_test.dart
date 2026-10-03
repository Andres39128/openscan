import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/image/perspective_warp.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';

/// Quad identidad: toda la imagen.
const _identity = OcrQuad(
  topLeft: OcrPoint(0, 0),
  topRight: OcrPoint(1, 0),
  bottomRight: OcrPoint(1, 1),
  bottomLeft: OcrPoint(0, 1),
);

/// Gradiente 8x8 para comparar píxel a píxel.
img.Image _gradient() {
  final image = img.Image(width: 8, height: 8);
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      image.setPixelRgb(x, y, x * 32, y * 32, 128);
    }
  }
  return image;
}

void main() {
  test('quad identidad preserva dimensiones y píxeles (±8/canal)', () {
    final jpeg = img.encodeJpg(_gradient());
    final out = warpJpg(WarpJob(jpeg: jpeg, quad: _identity, maxEdge: 8));

    expect(out.width, 8);
    expect(out.height, 8);

    final back = img.decodeJpg(out.jpeg)!;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final px = back.getPixel(x, y);
        expect((px.r - x * 32).abs() <= 8, isTrue, reason: 'r@$x,$y');
        expect((px.g - y * 32).abs() <= 8, isTrue, reason: 'g@$x,$y');
      }
    }
  });

  test('mitad superior recorta alto a la mitad', () {
    final jpeg = img.encodeJpg(_gradient());
    const half = OcrQuad(
      topLeft: OcrPoint(0, 0),
      topRight: OcrPoint(1, 0),
      bottomRight: OcrPoint(1, 0.5),
      bottomLeft: OcrPoint(0, 0.5),
    );
    final out = warpJpg(WarpJob(jpeg: jpeg, quad: half, maxEdge: 8));

    expect(out.width, 8);
    expect(out.height, 4);
  });

  test('JPEG ilegible lanza WarpFailed', () {
    expect(
      () => warpJpg(
        WarpJob(
          jpeg: Uint8List.fromList([0, 1, 2, 3]),
          quad: _identity,
        ),
      ),
      throwsA(isA<WarpFailed>()),
    );
  });
}
