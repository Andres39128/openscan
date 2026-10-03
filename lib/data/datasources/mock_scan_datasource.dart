import 'package:openscan/data/datasources/scan_datasource.dart';

/// Mock para dev/stg hasta F2 (bridges nativos reales).
class MockScanDataSource implements ScanDataSource {
  /// Crea el mock de F1.
  const new();

  @override
  Future<List<String>> scanDocuments() async => const ['mock/page_01.jpg'];
}
