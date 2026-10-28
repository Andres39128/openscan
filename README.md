# OpenScan

**Escáner de documentos offline para Android e iOS.** Sin cuenta, sin nube, sin ads, sin
watermark. Todo —imágenes, texto OCR, metadatos— se queda en el dispositivo, cifrado con
SQLCipher.

Flutter para la app. Nativo donde duele (VisionKit en iOS, ML Kit en Android), Dart en el resto.

---

## Por qué

La mayoría de escáneres de documentos son "gratis" porque tus documentos son el producto:
se suben a un servidor, te dan 3 escaneos gratis por día y el plan gratuito marca tu PDF
con watermark.

OpenScan toma el camino contrario. El escaneo, el OCR, la generación del PDF y el
almacenamiento ocurren localmente. No hay backend que escalar, no hay cobro por página y no
hay ninguna llamada de red en el camino principal.

| | OpenScan | Escáner típico |
|---|---|---|
| Requiere cuenta | No | Sí |
| Los documentos salen del dispositivo | Nunca | Sí |
| Ads / watermark | No | Casi siempre |
| Modo offline | Núcleo completo | Degradado |
| Precio | Gratis | Freemium |

---

## Funcionalidades

- **Escaneo por lotes** — captura multipágina, re-crop y reordenación antes de exportar
- **OCR offline** — español e inglés, en el dispositivo, con badge de baja confianza en los
  bloques dudosos
- **PDF buscable** — capa de texto invisible sobre la imagen, así que el PDF sí se puede buscar
- **Export** — PDF buscable (A4/Letter), o JPG por página (multipágina → PDF o ZIP)
- **Biblioteca cifrada** — documentos en una base SQLCipher, llave en Keychain / Keystore
- **Búsqueda local** — índice FTS5 full-text sobre el texto extraído
- **Firma y anotación** — dibuja una firma o marca; se aplana en la página antes de exportar
- **Backup** — export cifrado (AES-256-GCM + PBKDF2) al destino que elijas
- **Biometría opcional** — desbloqueo local de la app
- **Interfaz ES / EN**

---

## Arquitectura

```
lib/
  app/        bootstrap, routing, theme
  core/       puentes de plataforma, tipos de resultado, generación de PDF
  data/       datasources (SQLite/drift, method channels), repositories
  domain/     entities, casos de uso — Dart puro, sin Flutter ni dependencias de plataforma
  features/   scan · ocr · enhance · library · export · signature · viewer · settings
```

La capa de dominio no conoce MethodChannels, drift ni ML Kit. El trabajo específico de
plataforma vive detrás de puertos y adaptadores, así que las reglas de negocio se pueden
probar sin dispositivo.

**Decisiones clave** (razonamiento completo en [`docs/adr/`](docs/adr/)):

| ADR | Decisión |
|---|---|
| [001](docs/adr/ADR-001-native-scan-over-opencv.md) | Detección de bordes nativa sobre OpenCV en v1 |
| [002](docs/adr/ADR-002-vision-mlkit-over-tesseract.md) | OCR Vision + ML Kit sobre Tesseract como motor principal |
| [003](docs/adr/ADR-003-riverpod-over-bloc.md) | Riverpod sobre Bloc para estado |
| [004](docs/adr/ADR-004-drift-sqlcipher.md) | drift + SQLCipher sobre Hive/Isar |
| [005](docs/adr/ADR-005-single-pdf-source.md) | Fuente única de PDF en Dart (no usar el PDF nativo del scanner) |
| [006](docs/adr/ADR-006-crash-opt-in.md) | Telemetría de crashes solo opt-in |
| [007](docs/adr/ADR-007-saf-backup-no-cloud-sdks.md) | Backup E2E vía SAF sin SDKs de nube |

Documento de diseño completo: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Stack

- **UI / app**: Flutter stable · Dart 3 · Riverpod · go_router
- **Escaneo**: iOS `VisionKit` · Android Play Services ML Kit (`GmsDocScanner`)
- **OCR**: iOS `Vision` (`VNRecognizeTextRequest`) · Android ML Kit Text Recognition v2 (modelo embebido)
- **PDF**: `pdf` + `printing` (capa de texto buscable)
- **Almacenamiento**: `drift` + `sqlite3_sqlcipher` + FTS5 · llave en `flutter_secure_storage`
- **Seguridad**: `local_auth` (puerta biométrica opcional)
- **Calidad**: `very_good_analysis` · `dart_code_metrics` · `build_runner`

---

## Privacidad

Documentada en [`docs/PRIVACY.md`](docs/PRIVACY.md). En corto: tus documentos nunca salen del
dispositivo. Los únicos permisos pedidos son cámara, selector de fotos y biometría, y ninguno
implica enviar datos a ningún lado. La única excepción es la telemetría de crashes, que es
opt-in, está apagada por defecto y no está habilitada en esta versión.

---

## Desarrollo

```bash
flutter pub get
flutter run                 # build de debug
flutter test                # tests unitarios y de widgets
flutter build apk --release
```

El proyecto apunta al primer stable de Flutter que soporte los bindings en uso; la versión
exacta está fijada en CI y el build falla si el toolchain local diverge.

Mínimos: Android `minSdk 26`, iOS 15+.

---

## Estado

El alcance de v1 está implementado y documentado. v1.1 y v2 están definidos en
[`docs/PLAN.md`](docs/PLAN.md) — barcode/QR, share extension, TTS, auto-titulado, PDF/A,
papelera, bloqueo de capturas y sync con cuenta propia.

---

## Licencia

GPL-3.0 — ver [`LICENSE`](LICENSE).
