# ADR-002 — OCR Vision + ML Kit sobre Tesseract como motor principal

Fecha: 2026-10-03. Estado: aceptada.

Contexto: `flutter_tesseract_ocr` tiene mantenimiento flojo y suma 20MB+ de `.traineddata` por idioma. Vision (`VNRecognizeTextRequest`) y ML Kit Text Recognition v2 corren on-device con aceleración por hardware y cubren ES/EN latinos.

Decisión: motores principales = Vision (iOS) + ML Kit bundled (Android) tras `OcrEngine` abstracto (`Uint8List` → `OcrResult`). Tesseract solo como fallback futuro para idiomas no latinos, con ADR propia si se activa.

Consecuencias: APK/IPA contenidos, sin descargas de modelos en runtime, offline garantizado.
