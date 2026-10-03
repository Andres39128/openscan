import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/datasources/ocr_dto.dart';
import 'package:openscan/data/repositories/ocr_engine_impl.dart';

class _MockDs extends Mock implements OcrDataSource;

/// JPEG válido mínimo para el pipeline (el bridge lo recibe por path).
Uint8List _tinyJpg() {
  final image = img.Image(width: 4, height: 4);
  return img.encodeJpg(image);
}

void main() {
  test('mapea DTO a domain y borra el temporal', () async {
    final ds = _MockDs();
    when(() => ds.recognizeText(any(), any())).thenAnswer(
      (_) async => const OcrResultDto(
        fullText: 'Hola',
        blocks: [
          OcrBlockDto(
            text: 'Hola',
            x: 0,
            y: 0,
            w: 1,
            h: 1,
            conf: 0.9,
          ),
        ],
      ),
    );
    final tmp = await Directory.systemTemp.createTemp('ocr_test');
    addTearDown(() => tmp.delete(recursive: true));
    final engine = OcrEngineImpl(ds, () async => tmp);

    final out = await engine.recognize(_tinyJpg());

    expect(out.fullText, 'Hola');
    expect(out.blocks.single.box.conf, 0.9);
    // Temporal borrado: solo quedan . y .. (directorio vacío).
    expect(await tmp.list().toList(), isEmpty);
  });
}
