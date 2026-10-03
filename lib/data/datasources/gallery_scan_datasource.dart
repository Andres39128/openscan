import 'package:image_picker/image_picker.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';

/// Captura manual para la variante F-Droid: picker de galería
/// (sin GMS, sin permisos extra). Límite de 100 en el repositorio.
class GalleryScanDataSource implements ScanDataSource {
  /// Crea la fuente de galería.
  const new();

  @override
  Future<List<String>> scanDocuments() async {
    final files = await ImagePicker().pickMultiImage();
    return [for (final f in files) f.path];
  }
}
