import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openscan/app/flavors.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/data/db/fts.dart';
import 'package:openscan/features/library/application/library_providers.dart';
import 'package:openscan/features/scan/application/scan_actions.dart';
import 'package:openscan/features/scan/application/scan_providers.dart';

/// Búsqueda full-text sobre el texto indexado (FTS5).
// Tipo inferido a propósito: el nombre del family generado es inestable.
// ignore: specify_nonobvious_property_types
final searchProvider =
    FutureProvider.autoDispose.family<List<Document>, String>((ref, q) async {
  if (q.trim().isEmpty) return const [];
  final db = await ref.watch(appDbProvider.future);
  return await searchDocuments(db, q);
});

/// Home: estado de DB cifrada + scan → viewer + búsqueda FTS5.
class HomePage extends ConsumerStatefulWidget {
  /// Crea la home.
  const new({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(flavorProvider);
    final dbState = ref.watch(appDbProvider);
    final countState = ref.watch(documentCountProvider);
    final results = ref.watch(searchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: Text(flavor.appTitle),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          dbState.when(
            data: (_) => const Text('DB cifrada: OK'),
            loading: () => const Text('Abriendo DB cifrada…'),
            error: (e, _) => Text('DB error: $e'),
          ),
          const SizedBox(height: 8),
          countState.when(
            data: (n) => Text('Documentos: $n'),
            loading: () => const Text('Documentos: …'),
            error: (e, _) => Text('Conteo error: $e'),
          ),
          if (flavor.isOss)
            const Text(
              'Variante F-Droid: captura manual y sin OCR.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Buscar en documentos',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.when(
              data: (docs) => docs.isEmpty
                  ? const Center(
                      child: Text('Sin resultados. Exportá para indexar.'),
                    )
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: Text(docs[i].title),
                        subtitle: Text('${docs[i].pageCount} págs'),
                      ),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Búsqueda error: $e')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FilledButton.icon(
              icon: const Icon(Icons.document_scanner),
              label: const Text('Escanear'),
              onPressed: () async {
                await _scan(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Escanea (con permiso) y abre el viewer con el batch.
  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final pages = await scanWithPermission(context, ref);
    if (pages == null || pages.isEmpty) return;
    ref.read(currentBatchProvider.notifier).all = pages;
    if (!context.mounted) return;
    context.go('/viewer');
  }
}
