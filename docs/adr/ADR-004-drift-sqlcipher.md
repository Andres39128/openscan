# ADR-004 — drift + SQLCipher sobre Hive/Isar

Fecha: 2026-10-03. Estado: aceptada.

Contexto: se necesita búsqueda full-text (FTS5), cifrado transaccional (SQLCipher) y migraciones versionadas para pasar review de stores con discurso de privacidad. Hive/Isar son rápidos pero sin FTS5 real ni cifrado a nivel transacción.

Decisión: `drift` + `sqlite3_sqlcipher` + FTS5 vía companion y triggers, key AES-256 en `flutter_secure_storage`. Settings no sensibles en `shared_preferences`.

Consecuencias: queries tipadas y testeables, DB ilegible sin key; costo de setup inicial mayor que Hive.
