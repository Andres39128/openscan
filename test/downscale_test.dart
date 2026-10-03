import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/core/image/decode.dart';

void main() {
  test('achica al maxEdge manteniendo aspecto', () async {
    final image = img.Image(width: 16, height: 8);
    final small = await downscaleForOcr(img.encodeJpg(image), maxEdge: 8);
    final back = img.decodeJpg(small)!;
    expect(back.width, 8);
    expect(back.height, 4);
  });

  test('no agranda imágenes chicas', () async {
    final image = img.Image(width: 4, height: 4);
    final out = await downscaleForOcr(img.encodeJpg(image));
    final back = img.decodeJpg(out)!;
    expect(back.width, 4);
    expect(back.height, 4);
  });

  test('decodeSize real', () async {
    final image = img.Image(width: 7, height: 5);
    final size = await decodeSize(img.encodeJpg(image));
    expect(size.width, 7);
    expect(size.height, 5);
  });
}
