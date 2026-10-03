import 'package:equatable/equatable.dart';
import 'package:openscan/domain/entities/doc_type.dart';

/// Resultado de `classifyDocument` (v1.1). Contrato explícito, sin mapas.
/// Resultado de `classifyDocument` (v1.1). Contrato explícito, sin mapas.
class Classification extends Equatable {
  /// Crea una clasificación.
  const new({
    required this.tipo,
    required this.conf,
    this.emisor,
  });

  /// Tipo detectado.
  final DocType tipo;
  /// Emisor extraído, si se conoce.
  final String? emisor;
  /// Confianza 0..1.
  final double conf;

  @override
  List<Object?> get props => [tipo, emisor, conf];
}
