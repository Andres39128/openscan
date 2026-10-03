import 'package:equatable/equatable.dart';

/// Bloque OCR crudo del bridge. Coordenadas normalizadas 0..1.
class OcrBlockDto extends Equatable {
  /// Crea un bloque DTO.
  const new({
    required this.text,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.conf,
  });

  /// Parsea el mapa del MethodChannel.
  factory fromMap(Map<String, Object?> map) => OcrBlockDto(
        text: map['text']! as String,
        x: (map['x']! as num).toDouble(),
        y: (map['y']! as num).toDouble(),
        w: (map['w']! as num).toDouble(),
        h: (map['h']! as num).toDouble(),
        conf: (map['conf']! as num).toDouble(),
      );

  /// Texto reconocido.
  final String text;
  /// X normalizada.
  final double x;
  /// Y normalizada.
  final double y;
  /// Ancho normalizado.
  final double w;
  /// Alto normalizado.
  final double h;
  /// Confianza 0..1.
  final double conf;

  @override
  List<Object?> get props => [text, x, y, w, h, conf];
}

/// Resultado OCR crudo del bridge.
/// Resultado OCR crudo del bridge.
class OcrResultDto extends Equatable {
  /// Crea un resultado DTO.
  const new({required this.fullText, required this.blocks});

  /// Parsea el mapa del MethodChannel.
  factory fromMap(Map<String, Object?> map) {
    final rawBlocks = map['blocks']! as List;
    return OcrResultDto(
      fullText: map['fullText']! as String,
      blocks: rawBlocks
          .map((b) => OcrBlockDto.fromMap(Map<String, Object?>.from(b as Map)))
          .toList(),
    );
  }

  /// Texto plano.
  final String fullText;
  /// Bloques posicionados.
  final List<OcrBlockDto> blocks;

  @override
  List<Object?> get props => [fullText, blocks];
}
