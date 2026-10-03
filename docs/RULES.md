# OpenScan — Reglas de Producción (obligatorias)

Si violás una regla, el PR se rechaza. Sin excepciones.

## 1. Código

- `flutter analyze` + `dart_code_metrics` en 0 warnings. El CI bloquea merge si falla.
- `domain/` en Dart puro: prohibido importar `flutter/*`, `dart:io`, `drift`, `mlkit`, channels. Imágenes como `Uint8List`, geometría con value objects propios (`OcrBox`, `OcrQuad`), nunca `Rect`/`File`. Errores solo vía `AppFailure` (sealed, catálogo en ARCHITECTURE §5): jamás `Exception` cruda a UI, jamás mapas amorfos cruzando fronteras (`Classification`, no `{tipo: ...}`).
- Un `features/` no importa de otro. Reutilizable → mover a `core/` o `domain/`. `ocr/` y `export/` son application-only: prohibido crearles pantalla.
- Todo método de plataforma con timeout (15s scan, 10s OCR/barcode) y cancelación propagada a UI con progreso cancelable.
- Nada hardcodeado: idiomas, thresholds (`minConfidence`), paths, keys, formatos de título → config inyectada por flavor.
- `ponytail:` para marcar atajos deliberados con techo conocido. Ej: `// ponytail: auto-título con 5 regex AR; pasar a modelo local si precisión <80% con datos reales`.
- Prohibido: `print`, secretos en código, `// TODO` sin issue, assets sin compresión, dependencias nuevas sin ADR corto, `--update-goldens` en CI.

## 2. Nativo (Swift/Kotlin)

- Capa nativa tonta: solo llama SDK oficial y mapea a DTO. Sin ifs de negocio.
- Permisos pedidos en contexto (al tocar Escanear), con rationale en español. Si niega → pantalla que lleva a ajustes, nunca loop.
- iOS: `VNDocumentCameraViewController` tal cual Apple. Android: `GmsDocScanner` con `RESULT_FORMAT_JPEG` + `SCANNER_MODE_FULL`. Prohibido pedir PDF nativo: el PDF final siempre lo genera Dart (fuente única searchable).
- Manejar low-memory y rotación: no retener bitmaps full-res en memoria, downsample para preview.
- Barcode/QR con el mismo timeout y mapeo a `AppFailure` que OCR. Share extension y quick action: solo reciben archivos y los derivan a `importImages`; prohibida lógica de negocio en el target/extensión (iOS: App Group solo para handoff de archivos, sin keychain compartido).

## 3. Seguridad

- Key SQLCipher solo en `flutter_secure_storage`. Jamás en prefs, logs ni backup sin cifrar.
- DB, imágenes y PDFs viven en app sandbox. Share vía FileProvider / UIActivity con copia temporal que se borra.
- Biometría con `local_auth` + fallback PIN del sistema, no PIN propio.
- Antes de release: `sqlite3 app.db` sin key debe fallar + `strings` sobre APK/IPA no muestra keys/URLs internas.

## 4. Testing (mínimo para merge)

- Unit: todo UseCase + Repository con mocks. Coverage: `domain/` 100%, `data/` ≥70% (excluye `*.g.dart`: código generado). CI bloquea si baja.
- Widget: golden de viewer + estados error/permiso denegado (diff threshold fijo en CI; goldens se actualizan en local con review, nunca con `--update-goldens` en CI).
- Integración en dispositivo real: `scan→enhance→ocr→pdf buscable` (1 caso feliz + 1 sin texto) + restore de backup con password correcta e incorrecta.
- Manual pre-release: 10 páginas batch, modo avión, sin permisos, almacenamiento lleno, rotación durante scan.

## 5. Git y CI

- Conventional Commits, PRs <400 líneas, un feature = un PR con screenshots/video.
- Flavors: `dev` (mock engines, sin telemetría) / `staging` (real, icon beta) / `prod`.
- Pipeline: GitHub Actions (analyze → test --coverage → build AAB) + Firebase Test Lab (gama media, plan gratis) + Codemagic (IPA + TestFlight). Secrets (keystore, ASC API key) solo en Environments/Vars cifradas, jamás en repo.
- Versionado semver + changelog. Release solo desde tag `vX.Y.Z` construido y firmado por CI; prohibido subir a stores binarios firmados en local.
- Toda dependencia nueva: justificación en el PR + ADR corto + verificación de tamaño contra techos (PLAN §5).

## 6. Performance y tamaño

- Rechazar PR que exceda los techos de PLAN §5 (fuente única de números) o sume permiso nuevo sin justificar en descripción. `split-per-abi` solo para APK directo, jamás como argumento del AAB.
- Imágenes: max 300 DPI para PDF, thumbnails 256px para lista (60fps con 500 docs). Filtros/warp sobre >3MP obligatoriamente en `Isolate`; preview con downsample.
- OCR y filtros fuera del UI thread. Mostrar progreso cancelable, nunca spinner infinito.

## 7. Stores y legal

- Declarar en stores core sin recolección + crashes opt-in por separado. Prohibido declarar "no data collected" con Crashlytics activo por defecto: verificar con proxy que con opt-out hay 0 tráfico.
- Backup según spec de ARCHITECTURE §6 (fuente única de parámetros). Test: backup no abre sin password; `strings` sobre binarios no muestra keys/URLs internas.
- TTS: solo voces on-device. Prohibidas voces/servicios de red (rompen modo avión y Data Safety).
- Papelera: soft-delete + purge a 30d vía worker; "vaciar ahora" hace borrado seguro (filas + archivos + VACUUM). `FLAG_SECURE`/screenshot-block solo opcional por documento, nunca global sin setting visible.
- Textos de permisos (ES/EN) claros: por qué cámara y archivos.
- Política de privacidad publicada (contenido mínimo en PLAN §6) + contacto soporte antes de subir a closed testing.
- Crash-free ≥99.5%, ANR <0.5% para pasar a rollout 100%. Freno: si en staged crash-free <99% o ANR >1%, se pausa el rollout y sale hotfix antes de continuar.

## 8. Definition of Done de un feature

1. Funciona offline en modo avión
2. Tests verdes + coverage según §4
3. Probado en los modelos congelados en F1 (1 Android gama media + 1 iPhone real)
4. Sin warnings analyze, sin permiso nuevo oculto
5. Acciones icon-only con semanticLabel/tooltip + contraste AA
6. Docs actualizadas si cambió contrato o DB (ARCHITECTURE.md + ADR si aplica)
