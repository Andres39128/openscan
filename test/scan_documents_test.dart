import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/domain/entities/ocr_quad.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/domain/repositories/scan_repository.dart';
import 'package:openscan/domain/usecases/scan_documents.dart';

class _MockRepo extends Mock implements ScanRepository;

void main() {
  const quad = OcrQuad(
    topLeft: OcrPoint(0, 0),
    topRight: OcrPoint(1, 0),
    bottomRight: OcrPoint(1, 1),
    bottomLeft: OcrPoint(0, 1),
  );

  test('devuelve el batch del repositorio', () async {
    final repo = _MockRepo();
    const pages = [
      ScannedPage(id: 'a', imagePath: 'a.jpg', width: 100, height: 200),
    ];
    when(repo.scanDocuments).thenAnswer((_) async => pages);

    expect(await ScanDocuments(repo).call(), pages);
    verify(repo.scanDocuments).called(1);
  });

  test('propaga AppFailure sin envolver', () async {
    final repo = _MockRepo();
    when(repo.scanDocuments).thenThrow(const ScannerUnavailable());

    expect(
      ScanDocuments(repo).call,
      throwsA(isA<ScannerUnavailable>()),
    );
  });

  test('OcrQuad value object compara por valor', () {
    expect(quad, const OcrQuad(
      topLeft: OcrPoint(0, 0),
      topRight: OcrPoint(1, 0),
      bottomRight: OcrPoint(1, 1),
      bottomLeft: OcrPoint(0, 1),
    ));
  });
}
