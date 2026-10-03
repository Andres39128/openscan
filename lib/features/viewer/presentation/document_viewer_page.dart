import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openscan/core/image/decode.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/domain/entities/doc_filter.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/features/enhance/filter/apply_filter.dart';
import 'package:openscan/features/export/application/export_providers.dart';
import 'package:openscan/features/library/application/library_providers.dart';
import 'package:openscan/features/scan/application/scan_actions.dart';
import 'package:openscan/features/scan/application/scan_providers.dart';
import 'package:path/path.dart' as p;

/// Viewer F2: reordenar + borrar + recortar + agregar páginas.
class DocumentViewerPage extends ConsumerWidget {
  /// Crea el viewer sobre el batch actual.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(currentBatchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Documento (${batch.length})'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: batch.isEmpty
                ? null
                : () async {
                    await _export(context, ref, batch);
                  },
          ),
        ],
      ),
      body: batch.isEmpty
          ? const Center(child: Text('Sin páginas. Volvé y escaneá.'))
          : ReorderableListView.builder(
              itemCount: batch.length,
              onReorderItem: (oldI, newI) =>
                  ref.read(currentBatchProvider.notifier).move(oldI, newI),
              itemBuilder: (context, i) {
                final page = batch[i];
                return ListTile(
                  key: ValueKey(page.id),
                  leading: Image.file(
                    File(page.imagePath),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image),
                  ),
                  title: Text('Página ${i + 1}'),
                  subtitle: Text('${page.width}×${page.height}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Recortar',
                        icon: const Icon(Icons.crop),
                        onPressed: () => context.push('/crop', extra: i),
                      ),
                      IconButton(
                        tooltip: 'Borrar',
                        icon: const Icon(Icons.delete),
                        onPressed: () => ref
                            .read(currentBatchProvider.notifier)
                            .removeAt(i),
                      ),
                    ],
                  ),
                  onTap: () => _preview(context, ref, i),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        onPressed: () async {
          await _addMore(context, ref);
        },
      ),
    );
  }

  /// Escanea más páginas y las agrega al batch.
  Future<void> _addMore(BuildContext context, WidgetRef ref) async {
    final pages = await scanWithPermission(context, ref);
    if (pages == null || pages.isEmpty) return;
    ref.read(currentBatchProvider.notifier).addAll(pages);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agregadas: ${pages.length}')),
    );
  }

  /// Vista completa con zoom + filtros (el archivo se reemplaza).
  Future<void> _preview(BuildContext context, WidgetRef ref, int index) async {
    final original =
        await File(ref.read(currentBatchProvider)[index].imagePath)
            .readAsBytes();
    var currentPath = ref.read(currentBatchProvider)[index].imagePath;
    var filter = DocFilter.original;
    var busy = false;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 340,
                child: InteractiveViewer(
                  child: Image.file(
                    File(currentPath),
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
              ),
              if (busy) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final f in DocFilter.values)
                      ChoiceChip(
                        label: Text(filterLabel(f)),
                        selected: f == filter,
                        onSelected: busy
                            ? null
                            : (_) => _applyFilter(
                                  ctx,
                                  ref,
                                  index,
                                  original,
                                  f,
                                  (v) => setLocal(() {
                                    busy = v;
                                  }),
                                  (path, next) => setLocal(() {
                                    currentPath = path;
                                    filter = next;
                                  }),
                                ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aplica el filtro sobre el original y reemplaza el archivo.
  Future<void> _applyFilter(
    BuildContext context,
    WidgetRef ref,
    int index,
    Uint8List original,
    DocFilter filter,
    ValueChanged<bool> setBusy,
    void Function(String path, DocFilter filter) onDone,
  ) async {
    setBusy(true);
    try {
      final out = await applyFilter(original, filter);
      final size = await decodeSize(out);
      final dir = p.dirname(ref.read(currentBatchProvider)[index].imagePath);
      final path =
          '$dir/filt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(out, flush: true);
      final old = ref.read(currentBatchProvider)[index];
      ref.read(currentBatchProvider.notifier).replaceAt(
            index,
            ScannedPage(
              id: old.id,
              imagePath: path,
              width: size.width,
              height: size.height,
              position: old.position,
            ),
          );
      onDone(path, filter);
    } on AppFailure {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo filtrar')),
        );
      }
    } finally {
      setBusy(false);
    }
  }

  /// Exporta el batch a PDF searchable y lo comparte.
  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    List<ScannedPage> batch,
  ) async {
    final controller = TextEditingController(text: 'Escaneo');
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar PDF'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('EXPORTAR'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty || !context.mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Generando PDF…'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final db = await ref.read(appDbProvider.future);
      await ref.read(exportServiceProvider).exportBatch(
            db: db,
            pages: batch,
            title: title.trim(),
            now: DateTime.now(),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF listo y compartido')),
      );
    } on AppFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_exportError(e))),
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Mensaje por tipo de fallo de exportación.
  String _exportError(AppFailure e) => switch (e) {
        StorageFull() => 'Sin espacio para exportar',
        OcrFailed() => 'Falló el OCR',
        PdfFailed() => 'Falló el PDF',
        _ => 'No se pudo exportar',
      };
}
