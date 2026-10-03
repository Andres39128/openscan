import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/data/db/fts.dart';
import 'package:sqlite3/sqlite3.dart';

/// Crea un .db con schema v1 (sin FTS) para probar la migración a v2.
void _writeV1(String path) {
  sqlite3.open(path)
    ..execute(
      'CREATE TABLE documents (id TEXT NOT NULL PRIMARY KEY, '
      'title TEXT NOT NULL, created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL, '
      'page_count INTEGER NOT NULL DEFAULT 0)',
    )
    ..execute(
      'CREATE TABLE pages (id TEXT NOT NULL PRIMARY KEY, '
      'doc_id TEXT NOT NULL REFERENCES documents(id), '
      'path TEXT NOT NULL, width INTEGER NOT NULL, '
      'height INTEGER NOT NULL, position INTEGER NOT NULL)',
    )
    ..execute(
      'CREATE TABLE ocr_blocks (row_id INTEGER NOT NULL PRIMARY KEY '
      'AUTOINCREMENT, page_id TEXT NOT NULL REFERENCES pages(id), '
      'content TEXT NOT NULL, x REAL NOT NULL, y REAL NOT NULL, '
      'w REAL NOT NULL, h REAL NOT NULL, conf REAL NOT NULL)',
    )
    ..execute("INSERT INTO documents VALUES ('m1', 'Viejo', 1, 1, 0)")
    ..execute("INSERT INTO pages VALUES ('m1_p0', 'm1', '/tmp/x.jpg', 1, 1, 0)")
    ..execute(
      'INSERT INTO ocr_blocks (page_id, content, x, y, w, h, conf) '
      "VALUES ('m1_p0', 'texto migrado', 0, 0, 1, 1, 1)",
    )
    ..execute('PRAGMA user_version = 1')
    ..close();
}

void main() {
  test('migra v1→v2 con backfill buscable', () async {
    final dir = await Directory.systemTemp.createTemp('mig_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/m.db';
    _writeV1(path);

    final db = AppDb.openFile(File(path), 'k');
    addTearDown(db.close);

    // Backfill indexado por la migración.
    final hits = await searchDocuments(db, 'migrado');
    expect(hits.map((d) => d.id), ['m1']);
  });
}
