import 'package:openscan/domain/entities/ocr_quad.dart';
import 'package:openscan/domain/entities/scanned_page.dart';

/// Puerto de captura (ARCHITECTURE §5). Implementaciones en `data/`.
abstract class ScanRepository {
  /// Abre el scanner nativo. Devuelve páginas JPEG, máx 100.
  /// Abre el scanner nativo. Devuelve páginas JPEG, máx 100.
  Future<List<ScannedPage>> scanDocuments();

  /// Re-crop manual: warp en Dart (Isolate), dueño feature enhance.
  /// Re-crop manual: warp en Dart (Isolate), dueño feature enhance.
  Future<ScannedPage> recrop(ScannedPage page, OcrQuad quad);
}
