# ADR-003 — Riverpod sobre Bloc para estado

Fecha: 2026-10-03. Estado: aceptada.

Contexto: pipelines async largos (cámara → filtro → OCR → PDF) con cancelación y progreso. Bloc exige boilerplate de eventos/estados por cada paso; Riverpod 2 da providers compile-safe, cancelación y testeo directo de UseCases.

Decisión: Riverpod 2 como DI + estado. Sin `get_it` suelto. Regla: widgets observan providers, providers llaman UseCases, jamás channels directos.

Consecuencias: menos archivos, tests más simples; el equipo debe conocer `AsyncValue` y test de providers.
