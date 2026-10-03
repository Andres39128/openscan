import 'package:equatable/equatable.dart';

/// Página escaneada (JPEG en sandbox + dimensiones).
/// Página escaneada (JPEG en sandbox + dimensiones).
class ScannedPage extends Equatable {
  /// Crea una página.
  const new({
    required this.id,
    required this.imagePath,
    required this.width,
    required this.height,
    this.position = 0,
  });

  /// UUID de página.
  final String id;
  /// Path del JPEG en sandbox.
  final String imagePath;
  /// Ancho en px.
  final int width;
  /// Alto en px.
  final int height;
  /// Orden dentro del documento.
  final int position;

  /// Copia con posición actualizada (reordenar).
  ScannedPage copyWith({int? position}) => ScannedPage(
        id: id,
        imagePath: imagePath,
        width: width,
        height: height,
        position: position ?? this.position,
      );

  @override
  List<Object?> get props => [id, imagePath, width, height, position];
}
