/// Tipos de documento. Conjunto CERRADO (agregar valor = docs + validación).
enum DocType {
  /// Factura o boleta.
  factura,

  /// Ticket o comprobante corto.
  ticket,

  /// Documento genérico.
  documento,

  /// Contrato.
  contrato,

  /// Documento de identidad.
  identificacion,

  /// Sin clasificar.
  otro,
}
