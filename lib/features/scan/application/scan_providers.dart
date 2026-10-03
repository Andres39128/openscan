import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';
import 'package:openscan/data/repositories/scan_repository_impl.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/domain/repositories/scan_repository.dart';
import 'package:openscan/domain/usecases/scan_documents.dart';

/// Repositorio activo (datasource según flavor).
/// Repositorio activo (datasource según flavor).
final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepositoryImpl(ref.watch(scanDataSourceProvider)),
);

/// Batch actual en edición (viewer). Mutar solo vía estos métodos.
class BatchNotifier extends Notifier<List<ScannedPage>> {
  /// Estado inicial: batch vacío.
  @override
  List<ScannedPage> build() => const [];

  /// Batch actual (lectura).
  List<ScannedPage> get all => state;

  /// Reemplaza el batch completo.
  set all(List<ScannedPage> pages) => state = pages;

  /// Agrega páginas al final.
  void addAll(List<ScannedPage> pages) => state = [...state, ...pages];

  /// Reemplaza la página i.
  void replaceAt(int i, ScannedPage page) {
    final next = [...state];
    next[i] = page;
    state = next;
  }

  /// Borra la página i.
  void removeAt(int i) {
    final next = [...state]..removeAt(i);
    state = next;
  }

  /// Mueve de oldI a newI (índice ya ajustado) y renumera.
  void move(int oldI, int newI) {
    final next = [...state];
    final item = next.removeAt(oldI);
    next.insert(newI, item);
    state = [
      for (var i = 0; i < next.length; i++) next[i].copyWith(position: i),
    ];
  }
}

/// Batch actual en edición (viewer).
final currentBatchProvider =
    NotifierProvider<BatchNotifier, List<ScannedPage>>(
  BatchNotifier.new,
);

/// Caso de uso de captura.
/// Caso de uso de captura.
final scanDocumentsProvider = Provider<ScanDocuments>(
  (ref) => ScanDocuments(ref.watch(scanRepositoryProvider)),
);
