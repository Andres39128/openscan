# ADR-007 — Backup E2E vía SAF sin SDKs de nube

Fecha: 2026-10-03. Estado: aceptada.

Contexto: el backup a Drive/iCloud suele implementarse con SDKs de Google/Apple (scopes OAuth, tokens, tracking, peso). El requisito es E2E: la app nunca debe ver credenciales nube.

Decisión: el usuario elige destino con el picker del SO (`ACTION_OPEN_DOCUMENT_TREE` / FilePicker); la app escribe el zip AES-256-GCM y olvida la ruta salvo bookmark persistido. Sin SDKs, sin scopes, sin tokens guardados.

Consecuencias: UX un paso más manual a cambio de 0 permisos nube, +2MB max y Data Safety limpio.
