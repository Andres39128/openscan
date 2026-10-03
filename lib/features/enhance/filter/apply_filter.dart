import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:openscan/domain/entities/doc_filter.dart';

/// Aplica [filter] siempre en Isolate (nunca en UI).
Future<Uint8List> applyFilter(Uint8List jpeg, DocFilter filter) {
  if (filter == DocFilter.original) return Future.value(jpeg);
  return Isolate.run(() => _applySync(jpeg, filter));
}

/// Etiqueta visible del filtro.
String filterLabel(DocFilter filter) => switch (filter) {
      DocFilter.original => 'Original',
      DocFilter.gris => 'Gris',
      DocFilter.bn => 'B/N',
      DocFilter.mejorado => 'Mejorado',
    };

/// Versión síncrona (corre en Isolate).
Uint8List _applySync(Uint8List jpeg, DocFilter filter) {
  final src = img.decodeJpg(jpeg);
  if (src == null) throw StateError('JPEG ilegible');
  final out = switch (filter) {
    DocFilter.original => src,
    DocFilter.gris => img.grayscale(src),
    DocFilter.bn => _otsu(src),
    DocFilter.mejorado => img.adjustColor(src, contrast: 1.2),
  };
  return img.encodeJpg(out, quality: 92);
}

/// Binarización Otsu sobre luminancia.
img.Image _otsu(img.Image src) {
  final gray = img.grayscale(src);
  final hist = List.filled(256, 0);
  for (var y = 0; y < gray.height; y++) {
    for (var x = 0; x < gray.width; x++) {
      hist[gray.getPixel(x, y).r.toInt().clamp(0, 255)]++;
    }
  }
  final total = gray.width * gray.height;
  var sum = 0.0;
  for (var i = 0; i < 256; i++) {
    sum += i * hist[i];
  }
  var sumB = 0.0;
  var wB = 0;
  var best = -1.0;
  var thresh = 128;
  for (var t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sum - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > best) {
      best = between;
      thresh = t;
    }
  }
  final out = img.Image.from(gray);
  for (var y = 0; y < out.height; y++) {
    for (var x = 0; x < out.width; x++) {
      final v = out.getPixel(x, y).r > thresh ? 255 : 0;
      out.setPixelRgb(x, y, v, v, v);
    }
  }
  return out;
}
