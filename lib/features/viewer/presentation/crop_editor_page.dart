import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';
import 'package:openscan/features/scan/application/scan_providers.dart';

/// Editor de quad manual: 4 esquinas arrastrables sobre la página.
/// Aplica warp en Isolate vía `ScanRepository.recrop`.
class CropEditorPage extends ConsumerStatefulWidget {
  /// Crea el editor para la página `index` del batch.
  const new({required this.index, super.key});

  /// Índice en el batch actual.
  final int index;

  @override
  ConsumerState<CropEditorPage> createState() => _CropEditorPageState();
}

class _CropEditorPageState extends ConsumerState<CropEditorPage> {
  ui.Image? _image;
  OcrQuad _quad = const OcrQuad(
    topLeft: OcrPoint(0, 0),
    topRight: OcrPoint(1, 0),
    bottomRight: OcrPoint(1, 1),
    bottomLeft: OcrPoint(0, 1),
  );
  int? _drag;
  bool _busy = false;
  late final ImageStream _stream;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    final path = ref.read(currentBatchProvider)[widget.index].imagePath;
    _listener = ImageStreamListener((info, _) {
      setState(() => _image = info.image);
    });
    _stream = FileImage(File(path)).resolve(ImageConfiguration.empty);
    _stream.addListener(_listener);
  }

  @override
  void dispose() {
    _stream.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recortar'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _apply,
            child: const Text('APLICAR'),
          ),
        ],
      ),
      body: image == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, box) {
                final rect = _containRect(
                  box.maxWidth,
                  box.maxHeight,
                  image.width.toDouble(),
                  image.height.toDouble(),
                );
                return Stack(
                  children: [
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: Image.file(
                        File(
                          ref
                              .watch(currentBatchProvider)[widget.index]
                              .imagePath,
                        ),
                        width: rect.width,
                        height: rect.height,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: GestureDetector(
                        onPanDown: (d) => setState(
                          () => _drag = _nearest(
                            _px(_quad, rect.width, rect.height),
                            d.localPosition,
                          ),
                        ),
                        onPanUpdate: (d) {
                          final i = _drag;
                          if (i == null) return;
                          setState(
                            () => _quad = _moved(
                              _quad,
                              i,
                              _norm(
                                d.localPosition,
                                rect.width,
                                rect.height,
                              ),
                            ),
                          );
                        },
                        onPanEnd: (_) => setState(() => _drag = null),
                        child: CustomPaint(
                          painter: _QuadPainter(
                            _px(_quad, rect.width, rect.height),
                          ),
                        ),
                      ),
                    ),
                    if (_busy)
                      const Center(child: CircularProgressIndicator()),
                  ],
                );
              },
            ),
    );
  }

  /// Rect de `BoxFit.contain` centrado.
  Rect _containRect(double cw, double ch, double iw, double ih) {
    final s = (cw / iw < ch / ih) ? cw / iw : ch / ih;
    final w = iw * s;
    final h = ih * s;
    return Rect.fromLTWH((cw - w) / 2, (ch - h) / 2, w, h);
  }

  /// Esquinas del quad en px.
  List<Offset> _px(OcrQuad q, double w, double h) => [
        Offset(q.topLeft.x * w, q.topLeft.y * h),
        Offset(q.topRight.x * w, q.topRight.y * h),
        Offset(q.bottomRight.x * w, q.bottomRight.y * h),
        Offset(q.bottomLeft.x * w, q.bottomLeft.y * h),
      ];

  /// Offset en px → punto normalizado con clamp.
  OcrPoint _norm(Offset o, double w, double h) => OcrPoint(
        (o.dx / w).clamp(0.0, 1.0),
        (o.dy / h).clamp(0.0, 1.0),
      );

  /// Índice de la esquina más cercana (o null si lejos).
  int? _nearest(List<Offset> pts, Offset tap) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < pts.length; i++) {
      final d = (pts[i] - tap).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return bestD < 48 ? best : null;
  }

  /// Quad con la esquina i movida a [p].
  OcrQuad _moved(OcrQuad q, int i, OcrPoint p) {
    final pts = [q.topLeft, q.topRight, q.bottomRight, q.bottomLeft];
    pts[i] = p;
    return OcrQuad(
      topLeft: pts[0],
      topRight: pts[1],
      bottomRight: pts[2],
      bottomLeft: pts[3],
    );
  }

  /// Aplica el warp y reemplaza la página en el batch.
  Future<void> _apply() async {
    setState(() => _busy = true);
    try {
      final batch = [...ref.read(currentBatchProvider)];
      final out = await ref
          .read(scanRepositoryProvider)
          .recrop(batch[widget.index], _quad);
      batch[widget.index] = out;
      ref.read(currentBatchProvider.notifier).replaceAt(widget.index, out);
      if (mounted) context.pop();
    } on AppFailure {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo recortar')),
      );
    }
  }
}

/// Dibuja el polígono + manijas del quad.
class _QuadPainter extends CustomPainter {
  /// Crea el pintor sobre los puntos en px.
  new(this.points);

  /// Esquinas en px.
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i <= points.length; i++) {
      final p = points[i % points.length];
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = Colors.tealAccent;
    for (final p in points) {
      canvas.drawCircle(p, 10, dot);
    }
  }

  @override
  bool shouldRepaint(_QuadPainter old) => old.points != points;
}
