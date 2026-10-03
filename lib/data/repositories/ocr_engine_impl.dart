import 'dart:io';
import 'dart:typed_data';
import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/datasources/ocr_dto.dart';
import 'package:openscan/domain/entities/ocr_block.dart';
import 'package:openscan/domain/entities/ocr_box.dart';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:openscan/domain/repositories/ocr_engine.dart';
import 'package:path_provider/path_provider.dart';

/// Adaptador [OcrDataSource] → [OcrEngine].
/// El bridge trabaja con paths: los bytes se vuelcan a un temporal
/// que se borra siempre (sandbox, sin residuos).
class OcrEngineImpl implements OcrEngine {
  /// Crea el adaptador sobre el datasource activo según flavor.
  /// [_tmpDir] inyectable para tests (prod: `getTemporaryDirectory`).
  const new(this._dataSource, [this._tmpDir = getTemporaryDirectory]);

  final OcrDataSource _dataSource;
  final Future<Directory> Function() _tmpDir;

  @override
  Future<OcrResult> recognize(
    Uint8List imageBytes, {
    List<String> langs = const ['es', 'en'],
  }) async {
    final dir = await _tmpDir();
    final tmp = File(
      '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tmp.writeAsBytes(imageBytes, flush: true);
    try {
      final dto = await _dataSource.recognizeText(tmp.path, langs);
      return _map(dto);
    } finally {
      try {
        await tmp.delete();
      } on Object catch (_) {
        // Borrado best-effort: si ya no existe, nada que hacer.
      }
    }
  }

  /// Mapeo DTO → domain 1:1 (el badge de baja confianza es de UI).
  OcrResult _map(OcrResultDto dto) => OcrResult(
        fullText: dto.fullText,
        blocks: [
          for (final b in dto.blocks)
            OcrBlock(
              text: b.text,
              box: OcrBox(
                x: b.x,
                y: b.y,
                w: b.w,
                h: b.h,
                conf: b.conf,
              ),
            ),
        ],
      );
}
