# OpenScan — Arquitectura (documento fuente)

Estado: v1 aceptada. Cambios por ADR en `docs/adr/`.

## 1. Principios

1. Offline-first: el core funciona en modo avión. Red = 0 para scan/ocr/pdf (única excepción: crashes opt-in, ADR-006).
2. Nativo donde duele, Dart donde escala: bordes y OCR en SDKs oficiales, UI y orquestación en Flutter.
3. Puertos y adaptadores: el dominio no conoce MethodChannels, ni drift, ni ML Kit.
4. YAGNI v1: no OpenCV FFI, no Tesseract principal, no backend (rige también para v1.1: sin SDKs nube, ADR-007).

## 2. Stack fijado

- Flutter stable / Dart 3 / Riverpod 2 / go_router. Piso = primer stable que soporte los bindings usados; `flutter --version` se fija y congela en F1 y CI falla si difiere.
- Mínimos: Android `minSdk 26`, iOS 15+ (PHPicker completo + Vision accurate + Xcode vigente). Sin Play Services o VisionKit disponible → fallback captura manual + crop (ver §7).
- iOS scan: VisionKit `VNDocumentCameraViewController`
- Android scan: Play Services ML Kit Document Scanner (`GmsDocScanner`), se pide **solo JPEG**; el PDF final siempre lo genera Dart (fuente única, ADR-005)
- iOS OCR: Vision `VNRecognizeTextRequest` (.accurate, `recognitionLanguages: ['es-ES','en-US']`, Neural Engine)
- Android OCR: ML Kit Text Recognition v2 Latin, modelo bundled en APK/AAB (prohibida variante thin con descarga)
- PDF: `pdf` + `printing` (capa texto invisible para searchable; flag PDF/A-2b en v1.1)
- DB: `drift` + `sqlite3_sqlcipher` + FTS5. Key en `flutter_secure_storage`. Settings en `shared_preferences`. Biometría `local_auth`.
- Errores: `AppFailure` como sealed class Dart 3 (catálogo cerrado en §5). Entities con `equatable`. Sin `fpdart` (YAGNI).
- i18n UI: `flutter_localizations` + `.arb` (ES por defecto + EN). Sin dependencia extra de i18n.
- v1.1 (mismo principio, sin backend): barcode `google_mlkit_barcode_scanning` / `VNDetectBarcodesRequest`; intake `receive_sharing_intent` + Share Extension iOS + `quick_actions`; TTS `flutter_tts` solo voces locales; backup destino SAF (`ACTION_OPEN_DOCUMENT_TREE`) sin SDKs nube.
- Telemetría: core sin red. Crashlytics solo opt-in, declarado en stores, jamás en modo avión (ADR-006).
- Calidad: `very_good_analysis`, `dart_code_metrics`, `build_runner`

## 3. Capas y dependencias

```
UI (features/*/presentation)
  → Providers Riverpod
    → UseCases (domain, puros, testeables)
      → Repositories interfaces (domain)
        → Implementaciones (data) → DataSources → [MethodChannel | drift | pdf]
```

Reglas:
- `features/` jamás importa de otro `features/`. Compartido va en `core/` o `domain/`.
- Widgets jamás llaman MethodChannel directo. Solo UseCase → Repository.
- `domain/` sin imports Flutter. Solo Dart puro + `equatable` si hace falta.
- Todo I/O async con timeout + cancelación. Cámara/OCR corren fuera del UI thread (regla: imagen >3MP siempre en `Isolate`, §7).

## 4. Estructura

```
lib/
  app/            // flavors, bootstrap, router, theme. Flavors: dev (bundle suffix .dev, mock engines, sin telemetría) / staging (suffix .stg, engines reales, icono beta) / prod
  core/           // platform_bridge, permissions, security/keys, pdf_engine, tts_service, result/errors
  features/
    scan/         // presentation + application (providers) — sin lógica nativa acá
    enhance/      // filtros + recrop warp (dueño del warp en Isolate)
    ocr/          // application-only: sin pantalla, corre tras scan/enhance
    library/
    viewer/       // firma + anotación (flatten antes de exportar)
    export/       // application-only: pdf/share/backup, sin pantalla propia
  domain/         // entities, repositories (interfaces), usecases
  data/           // drift_db, daos, repositories impl, dtos
test/             // unit domain/data — mirrors de lib/
integration_test/ // scan→ocr→pdf en dispositivo real
docs/adr/         // decisiones
```

`ocr/` y `export/` son application-only (providers + UseCases, sin rutas UI): el OCR corre en background tras cada página y el export desde viewer/library. Crearles pantalla propia es un error de diseño.

## 5. Contratos clave

```dart
// domain/result/app_failure.dart — catálogo CERRADO (agregar valor = actualizar este doc + validación en el mismo cambio)
sealed class AppFailure {
  const AppFailure();
}
class PermissionDenied extends AppFailure {}
class ScannerUnavailable extends AppFailure {} // sin Play Services / VisionKit / cámara
class OcrFailed extends AppFailure {}
class StorageFull extends AppFailure {}
class PdfFailed extends AppFailure {}
class BackupFailed extends AppFailure {}
class WarpFailed extends AppFailure {} // warp degenerado o JPEG ilegible
class Cancelled extends AppFailure {} // usuario canceló: no es error, no loguea crash
```

```dart
// domain/repositories/scan_repository.dart — Dart puro, sin flutter/dart:io
abstract class ScanRepository {
  Future<List<ScannedPage>> scanDocuments(); // bridge nativo, solo JPEG, máx 100 págs
  Future<List<ScannedPage>> importImages(List<Uint8List> bytes); // galería/share: mismo pipeline batch
  Future<ScannedPage> recrop(ScannedPage page, OcrQuad quad); // warp en Dart (Isolate), dueño: feature enhance
}

// domain/repositories/ocr_engine.dart — coordenadas normalizadas 0..1, sin Rect de Flutter
class OcrBox { final double x, y, w, h; final double conf; }
class OcrBlock { final String text; final OcrBox box; }
class OcrResult { final String fullText; final List<OcrBlock> blocks; }
abstract class OcrEngine {
  Future<OcrResult> recognize(Uint8List imageBytes, {List<String> langs = const ['es', 'en']});
}

// domain/entities/doc_type.dart — conjunto CERRADO (ver regla catálogo arriba)
enum DocType { factura, ticket, documento, contrato, identificacion, otro }

// domain/usecases/classify_document.dart (v1.1)
class Classification { final DocType tipo; final String? emisor; final double conf; }
Classification classifyDocument(OcrResult ocr, List<Barcode> codes);

// domain/usecases/suggest_title.dart (v1.1) — Dart puro, coverage 100%
// "{DocType} {Emisor} {YYYY-MM}" | fallback "Escaneo YYYY-MM-DD HH:mm"

// domain/usecases/export_searchable_pdf.dart
// 1 firma/anotación con flatten a imagen + imagen mejorada abajo + N textos invisibles (OcrBox → coords PDF)
// 2 valida que el PDF sea textualmente buscable antes de guardar
// 3 nombre salida: openscan_{titulo}_{yyyyMMdd_HHmm}.pdf (ASCII, sin espacios)
```

Puente nativo: un método por acción, Pigeon o MethodChannel tipado:
`scanDocuments() -> List<String>` (paths JPEG), `recognizeText(path, langs) -> OcrResult`. Sin lógica de negocio en Swift/Kotlin, solo mapeo SDK → DTO. El PDF nativo del scanner no se usa: fuente única = generador Dart (ADR-005).

## 6. Datos (drift + SQLCipher + FTS5)

`schemaVersion: 1` en v1 (`documents`, `pages`, `ocr_blocks` + FTS5). v1.1 migra a v2 agregando `deleted_at` (papelera). Cada migración con test vN→vN+1.

`schemaVersion`: 1 = tablas; 2 (F3) = FTS5 + triggers + índices; 3 (v1.1) = papelera.

Tabla virtual FTS5 externa (`ocr_fts(text)`, `content='ocr_blocks'`) + triggers
insert/delete/update que la espejan + backfill en migración + índices
`idx_pages_doc` / `idx_blocks_page`. Búsqueda: join
`documents → pages → ocr_blocks → ocr_fts(rowid)` con `MATCH` sanitizado
(`buildMatchQuery` en `data/db/fts.dart`).

Jamás SQL crudo en features: solo DAOs drift testeados, con test de migración vN→vN+1.

- Key AES-256 generada en primer arranque, guardada en Keychain/Keystore. Rotación manual desde Ajustes (rekey SQLCipher + verificación de apertura).
- Borrado = borra filas + archivos + VACUUM. Thumbnails se regeneran, nunca se backupean. Temp de share/export se borra al cerrar el flujo o a las 24h vía purge worker.
- Backup = zip AES-256-GCM con key derivada de password del usuario vía PBKDF2 (600k iters, salt aleatorio por backup, NUL en memoria tras uso). Jamás ZipCrypto, jamás password hardcodeada.
- Migraciones drift versionadas, `fallback` prohibido en prod.

## 7. Fallbacks y permisos

- Sin Play Services (Huawei, custom ROMs, build F-Droid) o VisionKit no disponible: captura manual con `camera` + crop con quad + warp en Dart. Mismo `ScanRepository`, distinto DataSource inyectado por capability check en arranque.
- Filtros: toda imagen >3MP se procesa en `Isolate`, siempre (preview con downsample para no bloquear UI).
- Almacenamiento lleno: el scan se bloquea con mensaje accionable ("Liberá espacio o vaciá la papelera"), nunca crash ni documento a medias.
- Permisos: rationale en contexto (al tocar Escanear). Matriz:
  - Android ≤12: `CAMERA` + `READ_EXTERNAL_STORAGE` (solo import) / `WRITE` vía MediaStore.
  - Android 13+: `CAMERA` + `READ_MEDIA_IMAGES` (solo import). Sin `MANAGE_EXTERNAL_STORAGE`.
  - iOS: `NSCameraUsageDescription` + `PHOTO_LIBRARY_ADD` (guardar); acceso total a fotos solo para import, con `PHPicker`.
  - Denegado → pantalla que lleva a ajustes, nunca loop de pedido.

## 8. Seguridad y privacidad

Threat model (lo que se protege y de qué): documentos + key SQLCipher contra robo del dispositivo (cifrado en reposo + biometría), contra backups en nube sin cifrar (solo zip AES con password del usuario), contra miradas casuales (biometría + `FLAG_SECURE` opcional por documento).
- Sin analytics con ID publicitario. Crashlytics solo opt-in con IP anonimizada; con opt-out el core es 0 red (verificable con proxy en modo avión).
- `flutter_secure_storage` (kSecAccessDeviceOwner + EncryptedSharedPreferences).
- Biometría solo desbloquea la key en memoria, timeout 30s.
- Logging: log rotativo local (1MB x 3 archivos, sin PII ni secrets) + pantalla Diagnóstico con export manual. Prohibido loguear a red sin opt-in.
- Verificación: test que abre el .db con sqlite3 sin key y falla; test MitM con proxy confirma 0 tráfico en flujo core con opt-out.

## 9. Decisiones registradas (resumen — texto completo en `docs/adr/`)

- ADR-001 Nativo sobre OpenCV para bordes v1: Apple/Google ya dan UI+perspectiva+aceleración HW. OpenCV solo fase 2 para filtros.
- ADR-002 ML Kit/Vision sobre Tesseract: mantenimiento Flutter de tesseract roto + peso .traineddata. Tesseract solo fallback idiomas no latinos.
- ADR-003 Riverpod sobre Bloc: menos boilerplate para pipelines async cámara→filtro→ocr→pdf, compile-safe.
- ADR-004 drift+SQLCipher sobre Hive/Isar: FTS5 + cifrado transaccional necesario para búsqueda y compliance stores.
- ADR-005 Fuente única PDF en Dart: el PDF nativo del scanner no trae capa OCR; pedirlo duplica fuente de verdad.
- ADR-006 Telemetría crash solo opt-in: "no data collected" es falso con Crashlytics por defecto.
- ADR-007 Backup E2E vía SAF sin SDKs nube: la app nunca toca credenciales; el SO resuelve el destino.

## 10. Extensiones v1.1/v2 (puntos de encaje, sin romper capas)

- **QR/barcode:** `BarcodeRepository.scan(Uint8List) -> List<Barcode>` en `domain/`, DataSources ML Kit/Vision. El UseCase `classifyDocument` combina `OcrResult + List<Barcode>` → `Classification`. Sin permiso nuevo, sin modelo extra.
- **Intake:** share extension y `quick_actions` entran como `ScanRepository.importImages` — mismo pipeline batch que el scanner. iOS requiere App Group para compartir archivos con la extensión; Android intent-filter `SEND_MULTIPLE` con FileProvider. Sin lectura permanente de galería.
- **TTS:** `TtsService.speak(String)` en `core/` (no domain: es salida, no regla). Solo voces on-device; prohibidas voces de red en `RULES`.
- **Auto-títulos:** `suggestTitle(OcrResult, List<Barcode>) -> String` Dart puro en `domain/`, regex por país/tipo + fecha. Testeable sin dispositivo, coverage 100% exigible.
- **PDF/A-2b:** flag del generador en `core/pdf_engine`; validación con preflight de Acrobat en CI manual pre-release.
- **Papelera:** columna `deleted_at` (migración a schema v2) + purge en worker (`workmanager` / BGTask `processing` con `BGTaskSchedulerPermittedIdentifiers` en plist, ventana diaria). Borrado manual = soft-delete; borrado seguro real a los 30d o "vaciar ahora".
- **Backup E2E:** `BackupRepository.exportZip(password) -> zip` (v1) + `BackupDestination.saveToUserPickedDir(zip)` vía SAF. La app nunca pide scopes de Drive/iCloud ni guarda tokens: el SO resuelve el destino. Restaura con `pick + PBKDF2(password)`.
