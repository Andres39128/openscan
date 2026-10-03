import 'package:openscan/core/result/app_failure.dart' show AppFailure;
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/domain/repositories/scan_repository.dart';

/// Caso de uso: abrir scanner y devolver el batch.
class ScanDocuments {
  /// Crea el caso de uso sobre [ScanRepository].
  const new(this._repository);

  final ScanRepository _repository;

  /// Ejecuta el flujo. Lanza [AppFailure] en error, nunca `Exception` cruda.
  Future<List<ScannedPage>> call() => _repository.scanDocuments();
}
