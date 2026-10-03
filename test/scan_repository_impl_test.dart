import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';
import 'package:openscan/data/repositories/scan_repository_impl.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';
import 'package:openscan/domain/entities/scanned_page.dart';

class _MockDs extends Mock implements ScanDataSource;

const _quad = OcrQuad(
  topLeft: OcrPoint(0, 0),
  topRight: OcrPoint(1, 0),
  bottomRight: OcrPoint(1, 1),
  bottomLeft: OcrPoint(0, 1),
);

void main() {
  test('mapea paths a páginas ordenadas', () async {
    final ds = _MockDs();
    when(ds.scanDocuments).thenAnswer((_) async => ['a.jpg', 'b.jpg']);

    final pages = await ScanRepositoryImpl(ds).scanDocuments();

    expect(pages.map((e) => e.imagePath), ['a.jpg', 'b.jpg']);
    expect(pages.map((e) => e.position), [0, 1]);
    expect(pages.first.width, 0);
  });

  test('más de 100 páginas lanza StorageFull', () async {
    final ds = _MockDs();
    when(ds.scanDocuments)
        .thenAnswer((_) async => List.filled(101, 'x.jpg'));

    expect(
      ScanRepositoryImpl(ds).scanDocuments(),
      throwsA(isA<StorageFull>()),
    );
  });

  test('recrop escribe JPEG enderezado', () async {
    final ds = _MockDs();
    final dir = await Directory.systemTemp.createTemp('recrop_test');
    addTearDown(() => dir.delete(recursive: true));
    final src = img.Image(width: 8, height: 8);
    final srcPath = '${dir.path}/src.jpg';
    await File(srcPath).writeAsBytes(img.encodeJpg(src));

    const page = ScannedPage(id: 'p', imagePath: '', width: 0, height: 0);
    final out = await ScanRepositoryImpl(ds).recrop(
      ScannedPage(
        id: page.id,
        imagePath: srcPath,
        width: 8,
        height: 8,
      ),
      _quad,
    );

    expect(out.width, 8);
    expect(out.height, 8);
    expect(File(out.imagePath).existsSync(), isTrue);
  });
}
