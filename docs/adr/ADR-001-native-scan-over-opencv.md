# ADR-001 — Detección de bordes nativa sobre OpenCV en v1

Fecha: 2026-10-03. Estado: aceptada.

Contexto: VisionKit (iOS) y ML Kit Document Scanner (Android) dan UI de escaneo, detección en tiempo real y corrección de perspectiva con aceleración por hardware. OpenCV vía FFI exigiría compilar binarios, mantener puentes y replicar esa UI.

Decisión: v1 usa SDKs oficiales (solo JPEG). OpenCV (`opencv_dart`) entra en fase 2 únicamente para filtros (adaptive threshold, de-shadow), aislado en `Isolate` detrás del mismo `ScanRepository`.

Consecuencias: menos código nativo, menos tamaño, fallback manual requerido donde no haya Play Services/VisionKit.
