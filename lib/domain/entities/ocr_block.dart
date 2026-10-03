import 'package:equatable/equatable.dart';
import 'package:openscan/domain/entities/ocr_box.dart';

/// Bloque de texto con su posición para el PDF searchable.
/// Bloque de texto con su posición para el PDF searchable.
class OcrBlock extends Equatable {
  /// Crea un bloque texto+posición.
  const new({required this.text, required this.box});

  /// Texto reconocido.
  final String text;
  /// Posición para la capa invisible del PDF.
  final OcrBox box;

  @override
  List<Object?> get props => [text, box];
}
