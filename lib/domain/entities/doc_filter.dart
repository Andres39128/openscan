/// Filtros de página. Conjunto CERRADO.
enum DocFilter {
  /// Sin tocar.
  original,

  /// Luminancia.
  gris,

  /// Threshold Otsu en Isolate.
  bn,

  /// Contraste mejorado (mantiene color).
  mejorado,
}
