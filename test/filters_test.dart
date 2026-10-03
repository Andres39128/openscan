import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/domain/entities/doc_filter.dart';
import 'package:openscan/features/enhance/filter/apply_filter.dart';

/// 4x4 mitad roja / mitad negra.
Uint8List _halfJpg() {
  final image = img.Image(width: 4, height: 4);
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      if (x < 2) {
        image.setPixelRgb(x, y, 200, 0, 0);
      } else {
        image.setPixelRgb(x, y, 0, 0, 0);
      }
    }
  }
  return img.encodeJpg(image);
}

void main() {
  test('original devuelve los mismos bytes', () async {
    final jpeg = _halfJpg();
    expect(await applyFilter(jpeg, DocFilter.original), jpeg);
  });

  test('gris iguala canales', () async {
    final out = img.decodeJpg(await applyFilter(_halfJpg(), DocFilter.gris))!;
    final px = out.getPixel(0, 0);
    expect(px.r, px.g);
    expect(px.g, px.b);
    expect(px.r, greaterThan(0));
  });

  test('bn binariza a extremos', () async {
    final out = img.decodeJpg(await applyFilter(_halfJpg(), DocFilter.bn))!;
    final values = <int>{};
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final px = out.getPixel(x, y);
        expect(px.r, px.g);
        // Binarizado: solo extremos (tolerancia a artefactos JPEG).
        final v = px.r.toInt();
        expect(v <= 8 || v >= 247, isTrue);
        values.add(v <= 8 ? 0 : 255);
      }
    }
    expect(values, {0, 255});
  });

  test('etiquetas en español', () {
    expect(filterLabel(DocFilter.mejorado), 'Mejorado');
  });
}
