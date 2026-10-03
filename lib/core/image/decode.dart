import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Dimensiones de imagen (transferible a Isolate).
class ImageSize {
  /// Crea dimensiones.
  const new({required this.width, required this.height});

  /// Ancho en px.
  final int width;

  /// Alto en px.
  final int height;
}

/// Dimensiones del JPEG en Isolate (sin bloquear UI).
Future<ImageSize> decodeSize(Uint8List jpeg) => Isolate.run(() {
      final image = img.decodeJpg(jpeg);
      if (image == null) throw StateError('JPEG ilegible');
      return ImageSize(width: image.width, height: image.height);
    });

/// Reduce el JPEG a [maxEdge] para OCR (rápido) sin tocar el original.
/// El PDF usa la imagen full-res; el OCR, esta versión liviana.
Future<Uint8List> downscaleForOcr(Uint8List jpeg, {int maxEdge = 2000}) =>
    Isolate.run(() {
      final image = img.decodeJpg(jpeg);
      if (image == null) throw StateError('JPEG ilegible');
      final longest =
          image.width > image.height ? image.width : image.height;
      if (longest <= maxEdge) return jpeg;
      final scale = maxEdge / longest;
      final small = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
      return img.encodeJpg(small, quality: 90);
    });
