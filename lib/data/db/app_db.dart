import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// El import aplica el override del binario SQLCipher en el open.
// ignore: unused_import
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

part 'app_db.g.dart';

/// Documentos (schema v1; v1.1 migra a v2 con `deleted_at`).
class Documents extends Table {
  /// UUID del documento.
  TextColumn get id => text()();
  /// Título visible.
  TextColumn get title => text()();
  /// Epoch de creación.
  IntColumn get createdAt => integer()();
  /// Epoch de modificación.
  IntColumn get updatedAt => integer()();
  /// Cantidad de páginas (denormalizado).
  IntColumn get pageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Páginas JPEG en sandbox referenciadas por path.
class Pages extends Table {
  /// UUID de página.
  TextColumn get id => text()();
  /// FK a documents.
  TextColumn get docId => text().references(Documents, #id)();
  /// Path del JPEG en sandbox.
  TextColumn get path => text()();
  /// Ancho en px.
  IntColumn get width => integer()();
  /// Alto en px.
  IntColumn get height => integer()();
  /// Orden en el documento.
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bloques OCR para FTS5 (companion + triggers en F3).
class OcrBlocks extends Table {
  /// Rowid autoincremental (content_rowid de FTS).
  IntColumn get rowId => integer().autoIncrement()();
  /// FK a pages.
  TextColumn get pageId => text().references(Pages, #id)();
  /// Texto del bloque (columna FTS).
  TextColumn get content => text()();
  /// X normalizada.
  RealColumn get x => real()();
  /// Y normalizada.
  RealColumn get y => real()();
  /// Ancho normalizado.
  RealColumn get w => real()();
  /// Alto normalizado.
  RealColumn get h => real()();
  /// Confianza 0..1.
  RealColumn get conf => real()();
}

@DriftDatabase(tables: [Documents, Pages, OcrBlocks])
/// Base cifrada SQLCipher. Abrir solo vía `openFile`/`openDefault`/`memory`.
class AppDb extends _$AppDb {
  new _(super.e);

  /// Apertura cifrada sobre [file] con `PRAGMA key`.
  factory openFile(File file, String key) {
    // PRAGMA no acepta parámetros: la key va literal escapada.
    // Es base64url (sin comillas); el escape es defensa en profundidad.
    final safeKey = key.replaceAll("'", "''");
    return AppDb._(
      NativeDatabase.createInBackground(
        file,
        setup: (raw) => raw.execute("PRAGMA key = '$safeKey'"),
      ),
    );
  }

  /// Apertura en memoria (tests). En VM usa sqlite del sistema;
  /// el cifrado real se verifica en dispositivo (ver `app_db_test.dart`).
  factory memory() => AppDb._(NativeDatabase.memory());

  /// Ubicación prod: sandbox de la app.
  /// Ubicación prod: sandbox de la app.
  static Future<AppDb> openDefault(String key) async {
    // El import de sqlcipher_flutter_libs aplica el override del binario.
    final dir = await getApplicationDocumentsDirectory();
    return AppDb.openFile(File(p.join(dir.path, 'openscan.db')), key);
  }

  @override
  /// v1: tablas. v2 (F3): FTS5 + triggers. v3 (v1.1): papelera.
  @override
  int get schemaVersion => 2;

  /// Migraciones versionadas. `fallback` prohibido en prod (RULES §3).
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts(m);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await _createFts(m);
        },
      );

  /// Tabla virtual FTS5 + triggers espejo de `ocr_blocks`.
  Future<void> _createFts(Migrator m) async {
    final db = m.database;
    await db.customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS ocr_fts '
      "USING fts5(text, content='ocr_blocks', content_rowid='rowid')",
    );
    await db.customStatement(
      'CREATE TRIGGER IF NOT EXISTS ocr_blocks_ai '
      'AFTER INSERT ON ocr_blocks BEGIN '
      'INSERT INTO ocr_fts(rowid, text) '
      'VALUES (new.rowid, new.content); END',
    );
    await db.customStatement(
      'CREATE TRIGGER IF NOT EXISTS ocr_blocks_ad '
      'AFTER DELETE ON ocr_blocks BEGIN '
      'INSERT INTO ocr_fts(ocr_fts, rowid, text) '
      "VALUES ('delete', old.rowid, old.content); END",
    );
    await db.customStatement(
      'CREATE TRIGGER IF NOT EXISTS ocr_blocks_au '
      'AFTER UPDATE ON ocr_blocks BEGIN '
      'INSERT INTO ocr_fts(ocr_fts, rowid, text) '
      "VALUES ('delete', old.rowid, old.content); "
      'INSERT INTO ocr_fts(rowid, text) '
      'VALUES (new.rowid, new.content); END',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pages_doc ON pages(doc_id)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_blocks_page ON ocr_blocks(page_id)',
    );
    // Backfill por si se migra con datos (fila por fila:
    // INSERT..SELECT falla en FTS5 externo cuando hay filas).
    final pending = await db
        .customSelect(
          'SELECT row_id, content FROM ocr_blocks',
        )
        .get();
    for (final r in pending) {
      await db.customStatement(
        'INSERT INTO ocr_fts(rowid, text) VALUES (?, ?)',
        [r.read<int>('row_id'), r.read<String>('content')],
      );
    }
  }

  /// Cantidad de documentos (home F1).
  Future<int> documentCount() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM documents',
    ).getSingle();
    return row.read<int>('c');
  }
}
