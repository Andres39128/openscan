import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/result/app_failure.dart';

void main() {
  test('catálogo cerrado: cada subtipo es distinto', () {
    const failures = [
      PermissionDenied(),
      ScannerUnavailable(),
      OcrFailed(),
      StorageFull(),
      PdfFailed(),
      BackupFailed(),
      WarpFailed(),
      Cancelled(),
    ];
    expect(failures.map((f) => f.runtimeType).toSet(), hasLength(8));
  });

  test('Cancelled no es error: se distingue por tipo', () {
    const AppFailure f = Cancelled();
    expect(f, isA<Cancelled>());
    expect(f, isNot(isA<OcrFailed>()));
  });
}
