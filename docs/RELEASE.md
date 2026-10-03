# OpenScan — Release (F5)

## 0. Pre-requisitos (una vez)

`git init` + remoto + `fastlane/metadata/android/` completo + email de
soporte real en `docs/PRIVACY.md` + proyecto Firebase si se activa
telemetría (F5) + cuenta Play ($25) y Apple ($99/año).

## 1. Freeze y versión

- `CHANGELOG.md`: mover Unreleased a `vX.Y.Z (fecha)`.
- `pubspec.yaml`: `version: X.Y.Z+N` (N = +1 por release).
- Tag `vX.Y.Z`. CI construye y firma AAB/IPA (jamás binarios locales).

## 2. Gates antes de subir (CI en verde)

`flutter analyze` 0 issues, tests + coverage (domain 100% / data 70%),
AAB <80MB, crash-free ≥99.5% en la beta anterior si aplica.

## 3. Tracks

- Play: Internal → closed 14 días + 12 testers → staged 20% → 100%.
- TestFlight: beta review → testers → App Review (builds expiran 90 días).
- Freno: crash-free <99% o ANR >1% en staged → pausa + hotfix.
- F-Droid: pide build del flavor `oss` desde el tag.

## 4. Post-release

Monitorear crash-free/ANR 48h antes de subir el staged. Actualizar
`docs/STORE.md` si cambia cualquier declaración de datos.
