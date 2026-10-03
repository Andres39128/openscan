import 'package:equatable/equatable.dart';

/// Caja normalizada 0..1 sobre la imagen (nunca `Rect` de Flutter).
/// Caja normalizada 0..1 sobre la imagen (nunca `Rect` de Flutter).
class OcrBox extends Equatable {
  /// Crea una caja con confianza del motor.
  const new({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.conf,
  });

  /// Coordenada X normalizada 0..1.
  final double x;
  /// Coordenada Y normalizada 0..1.
  final double y;
  /// Ancho normalizado 0..1.
  final double w;
  /// Alto normalizado 0..1.
  final double h;

  /// Confianza 0..1 del motor OCR.
  final double conf;

  @override
  List<Object?> get props => [x, y, w, h, conf];
}
