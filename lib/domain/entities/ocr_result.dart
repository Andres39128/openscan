import 'package:equatable/equatable.dart';
import 'package:openscan/domain/entities/ocr_block.dart';
import 'package:openscan/domain/repositories/ocr_engine.dart' show OcrEngine;

/// Salida del [OcrEngine]: texto + bloques posicionados.
/// Salida del motor OCR: texto + bloques posicionados.
class OcrResult extends Equatable {
  /// Crea un resultado completo.
  const new({required this.fullText, required this.blocks});

  /// Texto plano concatenado.
  final String fullText;
  /// Bloques con posición y confianza.
  final List<OcrBlock> blocks;

  @override
  List<Object?> get props => [fullText, blocks];
}
