import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/data/datasources/mock_ocr_datasource.dart';
import 'package:openscan/data/datasources/mock_scan_datasource.dart';
import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';
import 'package:openscan/data/repositories/no_ocr_engine.dart';
import 'package:openscan/data/repositories/ocr_engine_impl.dart';
import 'package:openscan/data/repositories/scan_repository_impl.dart';
import 'package:openscan/domain/repositories/ocr_engine.dart';
import 'package:openscan/domain/repositories/scan_repository.dart';
import 'package:openscan/features/ocr/application/ocr_providers.dart';
import 'package:openscan/features/scan/application/scan_providers.dart';

Uint8List _bytes() => Uint8List.fromList([0]);

void main() {
  test('providers por defecto: bridges reales', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    expect(c.read(scanDataSourceProvider), isA<ScanDataSource>());
    expect(c.read(ocrDataSourceProvider), isA<OcrDataSource>());
    expect(c.read(scanRepositoryProvider), isA<ScanRepository>());
    expect(c.read(scanRepositoryProvider), isA<ScanRepositoryImpl>());
    expect(c.read(ocrEngineProvider), isA<OcrEngine>());
    expect(c.read(ocrEngineProvider), isA<OcrEngineImpl>());
  });

  test('variante oss: OCR vacío válido', () async {
    final out = await const NoOcrEngine().recognize(_bytes());
    expect(out.fullText, isEmpty);
    expect(out.blocks, isEmpty);
  });

  test('mocks dev responden', () async {
    const scan = MockScanDataSource();
    const ocr = MockOcrDataSource();
    expect(await scan.scanDocuments(), isNotEmpty);
    final dto = await ocr.recognizeText('x.jpg', ['es']);
    expect(dto.fullText.isNotEmpty, isTrue);
  });
}
