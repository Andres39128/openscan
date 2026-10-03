# ADR-006 — Telemetría de crashes solo opt-in

Fecha: 2026-10-03. Estado: aceptada.

Contexto: el posicionamiento es "nada sale del teléfono". Crashlytics por defecto envía crashes + identificadores y vuelve falsa la declaración "no data collected" en tiendas.

Decisión: Crashlytics compilado pero inactivo por defecto; pantalla de onboarding + Ajustes con opt-in explícito. Con opt-out, proxy confirma 0 tráfico. Data Safety declara ambos estados. Build F-Droid sin Crashlytics compilado.

Consecuencias: menos crashes visibles al inicio a cambio de credibilidad de privacidad; pantalla Diagnóstico con export manual de logs locales como alternativa.
