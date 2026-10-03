# ADR-005 — Fuente única de PDF en Dart (no usar el PDF nativo del scanner)

Fecha: 2026-10-03. Estado: aceptada.

Contexto: el Document Scanner de ML Kit puede devolver PDF, pero sin capa de texto OCR. Si se acepta ese PDF conviven dos generadores y el "searchable" deja de estar garantizado.

Decisión: al scanner solo se le pide JPEG. Todo PDF (v1 y PDF/A v1.1) lo genera `core/pdf_engine` con imagen + capa de texto invisible + validación de buscabilidad antes de guardar.

Consecuencias: un solo código a testear; firma/anotación hacen flatten a imagen para no invalidar la capa de texto.
