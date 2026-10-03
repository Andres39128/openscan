# OpenScan — Ficha de tiendas (F4)

## Google Play — Data Safety

- Recolección: núcleo sin recolección. Crashes solo con opt-in explícito
  (Ajustes → Telemetría). Sin SDK de crashes en F4: el switch guarda
  consentimiento para F5 (Firebase); hoy no sale ningún dato.
- Si el opt-in se activa en F5, declarar: registros de fallos + IDs de
  dispositivo, finalidad "diagnóstico", sin compartirse con terceros.
- Sin login (App access: "sin acceso especial"), sin ads, Everyone.
- Tipos de datos declarados hoy: ninguno.

## App Store — Privacy Nutrition

- Datos recopilados: ninguno (núcleo). Crash opt-in igual que Play.
- `ITSAppUsesNonExemptEncryption = NO` (solo cifrado estándar exempt:
  SQLCipher/AES/TLS). Sin IDFA.
- `PrivacyInfo.xcprivacy` en `ios/Runner/` (tracking NO, sin tipos
  recolectados, APIs: UserDefaults CA92.1, FileTimestamp C617.1,
  SystemBootTime 35F9.1).

## Release

1. Tag `vX.Y.Z` → CI firma AAB/IPA (jamás binarios locales).
2. Play Internal → closed 14 días + 12 testers → staged 20% → 100%.
3. TestFlight beta review → App Review (builds expiran a 90 días).
4. Freno: crash-free <99% o ANR >1% en staged → pausa + hotfix.
5. F-Droid: APK dedicada sin Play Services (fallback manual) ni Crashlytics,
   metadata en `fastlane/metadata/android/` (pendiente F5).

## Assets por release

Screenshots 6.7"/6.5" + tablet, feature graphic, descripción ES/EN,
URL de `docs/PRIVACY.md` publicada + email de soporte (pendiente F5).
