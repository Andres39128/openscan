/// Catálogo CERRADO de errores (ARCHITECTURE §5).
/// Agregar un valor = actualizar este archivo + validación en el mismo cambio.
sealed class AppFailure implements Exception {
  /// Crea la base del catálogo.
  const new();
}

/// Permiso denegado por el usuario.
class PermissionDenied extends AppFailure {
  /// Crea el fallo de permiso denegado.
  const new();
}

/// Sin Play Services / VisionKit / cámara disponible.
class ScannerUnavailable extends AppFailure {
  /// Crea el fallo de scanner no disponible.
  const new();
}

/// Falló el OCR nativo.
class OcrFailed extends AppFailure {
  /// Crea el fallo de OCR.
  const new();
}

/// Sin espacio para escribir.
class StorageFull extends AppFailure {
  /// Crea el fallo de almacenamiento lleno.
  const new();
}

/// Falló la generación del PDF.
class PdfFailed extends AppFailure {
  /// Crea el fallo de PDF.
  const new();
}

/// Falló el backup/restore.
class BackupFailed extends AppFailure {
  /// Crea el fallo de backup.
  const new();
}

/// Falló el warp de perspectiva (quad degenerado o JPEG ilegible).
class WarpFailed extends AppFailure {
  /// Crea el fallo de warp.
  const new();
}

/// El usuario canceló: no es error, no loguea crash.
class Cancelled extends AppFailure {
  /// Crea la cancelación del usuario.
  const new();
}
