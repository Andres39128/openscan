# OpenScan — Plan de Producto y Ejecución (v1 + backlog v1.1/v2)

> App tipo CamScanner, 100% free, offline-first. Flutter para Android + iOS. Objetivo: lanzar en Play Store + App Store (+ F-Droid).

## 1. Visión

Escáner de documentos rápido, privado y gratuito. Nada sale del teléfono salvo crashes con tu permiso explícito (opt-in declarado en tiendas). Nada se cobra. Diferencial vs CamScanner: sin cuenta, sin nube, sin watermark, sin ads.

## 2. Alcance v1 (MVP lanzable)

IN:
- Batch scan multi-página, máx 100 págs/documento (límite de memoria; superarlo muestra mensaje, no crash)
- Re-crop manual + reordenar páginas
- Filtros: Original (sin tocar) / Gris (luminancia) / B/N (threshold adaptativo en Isolate) / Mejorado (contraste + sharpen leve)
- OCR offline ES+EN (`langs: ['es','en']` por defecto) + búsqueda en librería; bloques bajo confianza (<0.5, config `minConfidence`) se indexan igual pero la UI muestra badge "revisar"
- PDF con texto buscable (searchable) + export JPG (1 JPG por página vía share; multi-página = PDF o ZIP de JPGs). Firma/anotación se fusionan a la imagen antes de generar el PDF (flatten: el searchable nunca se invalida)
- Librería: carpetas, tags, FTS5
- Firma dibujada + anotación básica
- Backup cifrado local (zip AES-256-GCM + PBKDF2, export manual; spec en ARCHITECTURE §6)
- Biometría como gate opcional
- Nombres de archivo export: `openscan_{titulo}_{yyyyMMdd_HHmm}.pdf` (ASCII, sin espacios)

OUT (v1.1 → v2, priorizado en §8):
- v1.1: QR/barcode, import + share extension, backup E2E a nube del usuario, TTS, auto-títulos, PDF/A, papelera + bloqueo screenshots
- v2: sync propia con cuentas, OCR tablas, MRZ/DNI, libros curvados, OpenCV avanzado, Tesseract fallback idiomas no latinos, traducción offline, búsqueda semántica

## 3. Roadmap 12 semanas (v1 en 8 + v1.1/v1.2 en 4)

### F1 (S1-2) — Scaffold
- Flavors dev/staging/prod, go_router, Riverpod, theme
- Drift + SQLCipher + flutter_secure_storage funcionando
- MethodChannels scan/ocr con mocks
- CI verde: analyze + test + build
- DoD: home vacía con DB cifrada creada (`flutter run --flavor prod` en Android; scheme `prod` en iOS). En F1 se fijan y congelan: `flutter --version` (piso = primer stable que soporte los bindings usados), modelos de prueba (1 Android gama media + 1 iPhone SE o similar) y licencia open source (§7)

### F2 (S3-4) — Captura
- iOS: VNDocumentCameraViewController vía MethodChannel
- Android: ML Kit Document Scanner API vía MethodChannel
- Viewer + re-crop manual + reordenar
- DoD: 10 páginas seguidas sin crash en los modelos congelados en F1

### F3 (S5-6) — Enhance + OCR + PDF
- Filtros Dart (gris/BN/mejorado simple), todo >3MP en `Isolate`, preview con downsample
- OcrEngine abstracto (Vision / ML Kit)
- PDF searchable (imagen + capa texto invisible)
- FTS5 search en librería
- DoD: PDF buscable, búsqueda <200ms con 500 docs

### F4 (S7) — Hardening
- local_auth, backup zip AES, manejo permisos
- Integration tests en dispositivo real
- Privacy manifests + Data Safety forms
- DoD: sin warnings analyze, coverage según RULES §4

### F5 (S8) — Lanzamiento
- Closed testing: Play Internal (14 días + 12 testers mínimo en cuentas nuevas) + TestFlight (beta review; builds expiran a 90 días)
- Screenshots por tamaño exigido (teléfonos 6.7"/6.5" + tablet), ficha, política privacidad (§6)
- Rollout 20% → 100%
- DoD: crash-free >99.5%, ANR <0.5%

## 4. Backlog por feature

| Feature | Fase | Issues | Criterio aceptación |
|---|---|---|---|
| scan | v1 | bridge iOS, bridge Android, batch, recrop | scan→viewer <2s/pág |
| enhance | v1 | 4 filtros, preview | preview <300ms |
| ocr | v1 | engine iOS, engine Android, FTS5 index | OCR <1.5s/pág en modelos F1 |
| export | v1 | pdf searchable, share, backup zip | PDF abre en Acrobat + buscable |
| library | v1 | carpetas, tags, búsqueda | 500 docs scroll 60fps |
| security | v1 | sqlcipher, biometría | key nunca en prefs, DB ilegible sin key |
| qr | v1.1 | barcode MLKit/Vision tras OcrEngine | QR factura detectado <1s, clasifica tipo doc |
| intake | v1.1 | import galería + share extension + quick action | recibir 10 imgs de WhatsApp → batch sin crash |
| tts | v1.1 | flutter_tts voces sistema | lee OCR en ES sin red |
| autotitle | v1.1 | reglas regex sobre OcrResult | 80% facturas auto-tituladas `"{DocType} {Emisor} {YYYY-MM}"`, fallback `"Escaneo YYYY-MM-DD HH:mm"` |

### F6 (v1.1, S9-10) — Adopción + confianza
Orden estricto (cada uno shipeable solo): 1) QR/barcode, 2) import + share extension + quick action, 3) TTS, 4) auto-títulos, 5) PDF/A-2b, 6) papelera 30d + `FLAG_SECURE` opcional.
DoD por ítem: sin permiso nuevo salvo declarado en §5/ARCHITECTURE §7, tamaño dentro de presupuesto incremental (§5), test integración propio.

### F7 (v1.2, S11-12) — Backup E2E + release minor
- Backup zip AES-256-GCM a destino SAF elegido por el usuario (Drive/iCloud/carpeta). App jamás ve credenciales nube.
- Rollout staged 20% → 100% con crash-free ≥99.5%.

## 5. Presupuesto técnico (no negociable)

- AAB <80MB (Play particiona por ABI solo; `split-per-abi` únicamente para APK directo: F-Droid / GitHub releases), IPA <100MB
- Base: `minSdk 26` Android (Play Services reciente para Doc Scanner), iOS 15+ (PHPicker completo + Vision accurate + soporte Xcode vigente). Dispositivos fuera de eso van al fallback de captura manual (ver ARCHITECTURE §7).
- Scan <2s/página, OCR <1.5s/página (modelos congelados en F1)
- Cold start <1.5s
- Core (scan/ocr/pdf/búsqueda) con 0 llamadas de red, verificable con proxy. Telemetría de crashes solo opt-in y declarada (ver §6).
- Presupuesto incremental v1.1 (verificado en CI por PR, bloquea merge si excede): QR/barcode +5MB max (mismo vendor ML Kit/Vision, sin modelo extra); TTS + import/share/quick actions + auto-títulos + PDF/A + papelera +1MB c/u max; backup E2E +2MB max (SAF, sin SDKs nube). Techo total v1.1: AAB <90MB, IPA <110MB. Traducción offline y embeddings semánticos quedan en v2 por costo 30-50MB.

## 6. Lanzamiento en tiendas

Play: App Bundle firmado solo por CI desde tag; Data Safety declara core sin recolección + crashes opt-in (nunca "no data collected" si Crashlytics está activo); 14 días closed + 12 testers; declarar "sin login" (App access), "sin ads", content rating Everyone; 8 screenshots + feature graphic.
App Store: Privacy Nutrition equivalente; `NSCameraUsageDescription` justificado; `ITSAppUsesNonExemptEncryption = NO` (solo cifrado estándar exempt: SQLCipher/AES/TLS); sin IDFA; TestFlight + App Review; política de privacidad URL pública.
Política de privacidad (mínimo): qué datos existen (documentos, key), dónde viven (solo dispositivo), crashes opt-in (qué mandan, cómo desactivar), sin cuentas ni tracking, contacto soporte, fecha de vigencia.
F-Droid: APK firmada dedicada (sin Play Services → fallback manual obligatorio en ese build), metadata fastlane (`fastlane/metadata/android/`), sin Crashlytics compilado.
Ambas: sin SDKs de ads/analytics con tracking.

## 7. Sostenibilidad (free para siempre)

Sin ads, sin paywall, sin backend propio. Costos fijos (Play $25 único, Apple $99/año, CI) se cubren con: repo open source + GitHub Sponsors / donaciones + distribución F-Droid. Licencia recomendada: GPL-3.0-only (copyleft: impide forks cerrados de pago; compatible con Play/App Store/F-Droid) — se fija en F1. Cualquier SDK con tracking futuro requiere ADR y actualización de Data Safety antes de mergearse.

## 8. Backlog v1.1/v2 (orden de ejecución, con dependencias)

| # | Ítem | Depende de | Por qué en ese orden |
|---|---|---|---|
| 1 | QR/barcode (ML Kit Barcode + VNDetectBarcodesRequest) | OcrEngine v1 | Mismo vendor, ~0 fricción permisos; clasifica facturas/boletos desde día 1 |
| 2 | Import galería + share extension + quick action "Escanear" | ScanRepository v1 | Principal driver de adopción; exige target/extensión nuevo + App Group + provisioning: hacerlo con tiempo, no contra el release |
| 3 | TTS voces del sistema | OcrResult v1 | Solo `flutter_tts`, prohibidas voces de red; accesibilidad barata |
| 4 | Auto-títulos por regex | OcrResult v1 | Dart puro en domain (`SuggestTitle`), testeable sin dispositivo |
| 5 | PDF/A-2b | Generador PDF v1 | Flag del package `pdf`; validar en Acrobat preflight |
| 6 | Papelera 30d + `FLAG_SECURE`/screenshot opcional | Schema drift v1 | Requiere migración a schema v3 (`deleted_at` + purge worker: WorkManager / BGTask `processing` + `BGTaskSchedulerPermittedIdentifiers` en plist) |
| 7 | Backup E2E a nube del usuario (SAF) | Backup zip v1 | Sin SDKs de Google/Apple: el usuario elige destino, la key la deriva su password; la app nunca toca credenciales nube |
| 8 | Traducción offline (v2) | Cuota tamaño | Pesa 30MB+ por par de idiomas; solo tras agotar presupuesto v1.1 |
| 9 | Búsqueda semántica local (v2) | Cuota tamaño | Embeddings TFLite 30-50MB; solo si FTS5 + tags se quedan cortos con datos reales |
