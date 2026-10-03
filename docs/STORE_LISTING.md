# OpenScan — Fichas de tienda (F5)

## Google Play (ver `fastlane/metadata/android/`)

- Título (30): ver `title.txt` por idioma.
- Descripción corta (80) y completa: en metadata.
- Categoría: Productividad. Rating: Everyone. Sin ads, sin login.
- Gráficos: 8 screenshots (teléfonos 6.7"/6.5" + tablet 10") + feature
  graphic 1024×500. Contenido sugerido: 1) batch scan, 2) re-crop,
  3) filtros, 4) OCR + búsqueda, 5) PDF searchable, 6) firma,
  7) backup cifrado, 8) ajustes/privacidad.

## App Store

- Nombre: OpenScan. Subtítulo (30): `Free private doc scanner` /
  `Escáner gratis y privado`.
- Keywords (100): `scanner,pdf,ocr,scan,document,offline,private,free` /
  `escaner,pdf,ocr,escanear,documento,offline,privado,gratis`.
- Descripción: traducir `full_description.txt`.
- Screenshots: 6.7" + 6.5" + iPad 13". Sin IDFA, sin tracking.

## F-Droid (flavor `oss`)

- Mismo ID (`com.openscan.app`), firmado por F-Droid, sin GMS ni Crashlytics.
- La variante oss usa galería + sin OCR (marcado en la app).
- Anti-features: ninguna (sin tracking, sin dependencias privativas).
