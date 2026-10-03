import 'package:drift/drift.dart';
import 'package:openscan/data/db/app_db.dart';

/// Sanitiza texto libre a query FTS5: cada término entrecomillado.
/// `factura edesur` → `"factura" "edesur"`.
String buildMatchQuery(String input) {
  final terms = input
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => '"${t.replaceAll('"', '""')}"');
  final q = terms.join(' ');
  return q.isEmpty ? '""' : q;
}

/// Búsqueda full-text: documentos con páginas que matchean, recientes primero.
Future<List<Document>> searchDocuments(AppDb db, String query) async {
  final rows = await db
      .customSelect(
        'SELECT DISTINCT d.* FROM documents d '
        'JOIN pages p ON p.doc_id = d.id '
        'JOIN ocr_blocks b ON b.page_id = p.id '
        'JOIN ocr_fts f ON f.rowid = b.rowid '
        'WHERE ocr_fts MATCH ? ORDER BY d.updated_at DESC',
        variables: [Variable.withString(buildMatchQuery(query))],
      )
      .get();
  return [
    for (final r in rows)
      Document(
        id: r.read<String>('id'),
        title: r.read<String>('title'),
        createdAt: r.read<int>('created_at'),
        updatedAt: r.read<int>('updated_at'),
        pageCount: r.read<int>('page_count'),
      ),
  ];
}
