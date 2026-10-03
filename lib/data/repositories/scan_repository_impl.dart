import 'dart:io';
import 'dart:isolate';
import 'package:openscan/core/image/perspective_warp.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/domain/repositories/scan_repository.dart';
import 'package:path/path.dart' as p;

/// Adaptador [ScanDataSource] → [ScanRepository]. Sin lógica de negocio.
class ScanRepositoryImpl implements ScanRepository {
  /// Crea el adaptador sobre el datasource activo.
  const new(this._dataSource);

  final ScanDataSource _dataSource;

  @override
  /// Mapea paths → páginas con límite de 100 (PLAN §2).
  @override
  Future<List<ScannedPage>> scanDocuments() async {
    final paths = await _dataSource.scanDocuments();
    if (paths.length > 100) throw const StorageFull();
    return [
      for (var i = 0; i < paths.length; i++)
        ScannedPage(
          id: 'page_${DateTime.now().millisecondsSinceEpoch}_$i',
          imagePath: paths[i],
          width: 0,
          height: 0,
          position: i,
        ),
    ];
  }

  @override
  /// Warp en Isolate (dueño: enhance). Escribe un JPEG nuevo en sandbox.
  @override
  Future<ScannedPage> recrop(ScannedPage page, OcrQuad quad) async {
    try {
      final bytes = await File(page.imagePath).readAsBytes();
      final warped = await Isolate.run(
        () => warpJpg(WarpJob(jpeg: bytes, quad: quad)),
      );
      final outPath =
          '${p.dirname(page.imagePath)}/recrop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(warped.jpeg, flush: true);
      return ScannedPage(
        id: page.id,
        imagePath: outPath,
        width: warped.width,
        height: warped.height,
        position: page.position,
      );
    } on FileSystemException {
      throw const WarpFailed();
    }
  }
}
