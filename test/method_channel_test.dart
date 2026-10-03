import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/platform_bridge/channels.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/data/datasources/method_channel_ocr_datasource.dart';
import 'package:openscan/data/datasources/method_channel_scan_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const scan = MethodChannelScanDataSource();
  const ocr = MethodChannelOcrDataSource();

  group('scan', () {
    test('lista de paths', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scanChannel, (call) async => ['a.jpg']);
      expect(await scan.scanDocuments(), ['a.jpg']);
    });

    test('null → lista vacía', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scanChannel, (call) async => null);
      expect(await scan.scanDocuments(), isEmpty);
    });

    test('BUSY (doble tap) → Cancelled silencioso', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scanChannel, (call) async {
        throw PlatformException(code: 'BUSY');
      });
      expect(scan.scanDocuments(), throwsA(isA<Cancelled>()));
    });

    test('PlatformException → ScannerUnavailable', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(scanChannel, (call) async {
        throw PlatformException(code: 'UNAVAILABLE');
      });
      expect(scan.scanDocuments(), throwsA(isA<ScannerUnavailable>()));
    });
  });

  group('ocr', () {
    test('parsea DTO', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ocrChannel, (call) async => {
                'fullText': 'Hola',
                'blocks': [
                  {
                    'text': 'Hola',
                    'x': 0,
                    'y': 0,
                    'w': 1,
                    'h': 1,
                    'conf': 1,
                  },
                ],
              });
      final dto = await ocr.recognizeText('a.jpg', ['es']);
      expect(dto.fullText, 'Hola');
      expect(dto.blocks.single.text, 'Hola');
    });

    test('null y error → OcrFailed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ocrChannel, (call) async => null);
      expect(
        ocr.recognizeText('a.jpg', ['es']),
        throwsA(isA<OcrFailed>()),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ocrChannel, (call) async {
        throw PlatformException(code: 'OCR_FAILED');
      });
      expect(
        ocr.recognizeText('a.jpg', ['es']),
        throwsA(isA<OcrFailed>()),
      );
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(scanChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ocrChannel, null);
  });
}
