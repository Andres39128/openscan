import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/data/datasources/method_channel_scan_datasource.dart';

/// Fuente de captura. Prod = MethodChannel (F2); dev/stg = mock (bootstrap).
/// Fuente de captura. Prod = MethodChannel (F2); dev/stg = mock.
abstract class ScanDataSource {
  /// Devuelve paths JPEG del sandbox.
  /// Devuelve paths JPEG del sandbox.
  Future<List<String>> scanDocuments();
}

/// Instancia activa (sobrescrita por mocks según flavor).
/// Instancia activa (sobrescrita por mocks según flavor).
final scanDataSourceProvider = Provider<ScanDataSource>(
  (ref) => const MethodChannelScanDataSource(),
);
