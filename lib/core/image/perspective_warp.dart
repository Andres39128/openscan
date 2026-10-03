import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';

/// Trabajo de warp, transferible a un Isolate (solo datos planos).
class WarpJob {
  /// Crea el trabajo de enderezado.
  const new({
    required this.jpeg,
    required this.quad,
    this.maxEdge = 2000,
    this.quality = 92,
  });

  /// JPEG origen.
  final Uint8List jpeg;

  /// Quad normalizado 0..1 a enderezar.
  final OcrQuad quad;

  /// Lado máximo de salida (achica, nunca agranda).
  final int maxEdge;

  /// Calidad JPEG de salida.
  final int quality;
}

/// Salida del warp (bytes + dimensiones reales).
class WarpResult {
  /// Crea el resultado del warp.
  const new({
    required this.jpeg,
    required this.width,
    required this.height,
  });

  /// JPEG enderezado.
  final Uint8List jpeg;

  /// Ancho real de salida.
  final int width;

  /// Alto real de salida.
  final int height;
}

/// Endereza el quad del trabajo a un rectángulo (homografía + bilineal).
/// Puro y testeable. Corre en Isolate (`Isolate.run`), nunca en UI.
WarpResult warpJpg(WarpJob job) {
  img.Image? src;
  try {
    src = img.decodeJpg(job.jpeg);
  } on Object catch (_) {
    throw const WarpFailed();
  }
  if (src == null) throw const WarpFailed();

  final sw = src.width.toDouble();
  final sh = src.height.toDouble();
  final q = [
    job.quad.topLeft,
    job.quad.topRight,
    job.quad.bottomRight,
    job.quad.bottomLeft,
  ];
  final org = q
      .map((p) => math.Point(p.x * sw, p.y * sh))
      .toList();

  // Tamaño destino en px: promedios de lados opuestos, capado a maxEdge.
  final dw = (_dist(org[0], org[1]) + _dist(org[3], org[2])) / 2;
  final dh = (_dist(org[0], org[3]) + _dist(org[1], org[2])) / 2;
  final scale = math.min(1, job.maxEdge / math.max(dw, dh));
  final outW = math.max(1, (dw * scale).round());
  final outH = math.max(1, (dh * scale).round());

  // Homografía destino → origen (h8 = 1), Gauss-Jordan 8x8.
  final fw = outW.toDouble();
  final fh = outH.toDouble();
  final dst = <math.Point<double>>[
    const math.Point<double>(0, 0),
    math.Point<double>(fw, 0),
    math.Point<double>(fw, fh),
    math.Point<double>(0, fh),
  ];
  final h = _homography(dst, org);

  final out = img.Image(width: outW, height: outH);
  for (var v = 0; v < outH; v++) {
    for (var u = 0; u < outW; u++) {
      final d = h[6] * u + h[7] * v + 1;
      if (d.abs() < 1e-9) continue; // Degenerado: píxel negro.
      final sx = (h[0] * u + h[1] * v + h[2]) / d;
      final sy = (h[3] * u + h[4] * v + h[5]) / d;
      final px = _bilinear(src, sx, sy);
      out.setPixelRgb(u, v, px[0], px[1], px[2]);
    }
  }
  return WarpResult(
    jpeg: img.encodeJpg(out, quality: job.quality),
    width: outW,
    height: outH,
  );
}

/// Distancia euclídea en px.
double _dist(math.Point<double> a, math.Point<double> b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

/// Resuelve H (8 elems, h8 = 1) que mapea [dst] → [org]. Lanza [WarpFailed]
/// si el quad es degenerado.
List<double> _homography(
  List<math.Point<double>> dst,
  List<math.Point<double>> org,
) {
  final m = List.generate(8, (_) => List<double>.filled(9, 0));
  for (var i = 0; i < 4; i++) {
    final x = dst[i].x;
    final y = dst[i].y;
    final xp = org[i].x;
    final yp = org[i].y;
    m[i * 2] = [x, y, 1, 0, 0, 0, -x * xp, -y * xp, xp];
    m[i * 2 + 1] = [0, 0, 0, x, y, 1, -x * yp, -y * yp, yp];
  }
  // Gauss-Jordan con pivoteo parcial.
  for (var col = 0; col < 8; col++) {
    var pivot = col;
    for (var row = col + 1; row < 8; row++) {
      if (m[row][col].abs() > m[pivot][col].abs()) pivot = row;
    }
    if (m[pivot][col].abs() < 1e-12) throw const WarpFailed();
    final tmp = m[col];
    m[col] = m[pivot];
    m[pivot] = tmp;
    final div = m[col][col];
    for (var j = col; j < 9; j++) {
      m[col][j] /= div;
    }
    for (var row = 0; row < 8; row++) {
      if (row == col) continue;
      final factor = m[row][col];
      for (var j = col; j < 9; j++) {
        m[row][j] -= factor * m[col][j];
      }
    }
  }
  return [for (var i = 0; i < 8; i++) m[i][8]];
}

/// Muestreo bilineal con clamp a bordes. Devuelve [r, g, b].
List<int> _bilinear(img.Image src, double x, double y) {
  final x0 = x.floor().clamp(0, src.width - 1);
  final y0 = y.floor().clamp(0, src.height - 1);
  final x1 = math.min(x0 + 1, src.width - 1);
  final y1 = math.min(y0 + 1, src.height - 1);
  final fx = (x - x0).clamp(0.0, 1.0);
  final fy = (y - y0).clamp(0.0, 1.0);
  final p00 = src.getPixel(x0, y0);
  final p10 = src.getPixel(x1, y0);
  final p01 = src.getPixel(x0, y1);
  final p11 = src.getPixel(x1, y1);
  int mix(num a, num b, num c, num d) => (a * (1 - fx) * (1 - fy) +
          b * fx * (1 - fy) +
          c * (1 - fx) * fy +
          d * fx * fy)
      .round();
  return [
    mix(p00.r, p10.r, p01.r, p11.r),
    mix(p00.g, p10.g, p01.g, p11.g),
    mix(p00.b, p10.b, p01.b, p11.b),
  ];
}
