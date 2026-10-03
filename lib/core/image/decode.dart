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
