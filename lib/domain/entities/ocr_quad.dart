import 'package:equatable/equatable.dart';

/// Punto normalizado 0..1.
/// Punto normalizado 0..1.
class OcrPoint extends Equatable {
  /// Crea un punto.
  const new(this.x, this.y);

  /// X normalizada.
  final double x;
  /// Y normalizada.
  final double y;

  @override
  List<Object?> get props => [x, y];
}

/// Cuadrilátero de re-crop manual (nunca tipos de Flutter).
/// Cuadrilátero de re-crop manual (nunca tipos de Flutter).
class OcrQuad extends Equatable {
  /// Crea un quad de 4 esquinas.
  const new({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// Esquina superior izquierda.
  final OcrPoint topLeft;
  /// Esquina superior derecha.
  final OcrPoint topRight;
  /// Esquina inferior derecha.
  final OcrPoint bottomRight;
  /// Esquina inferior izquierda.
  final OcrPoint bottomLeft;

  @override
  List<Object?> get props => [topLeft, topRight, bottomRight, bottomLeft];
}
