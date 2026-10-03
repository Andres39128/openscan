import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/features/settings/application/settings_repository.dart';

/// Repositorio de settings.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => const SettingsRepository(),
);

/// Bloqueo biométrico activo.
final biometricLockProvider = FutureProvider<bool>((ref) async {
  return await ref.watch(settingsRepositoryProvider).biometricLock();
});

/// Telemetría opt-in (consentimiento; SDK en F5).
final telemetryOptInProvider = FutureProvider<bool>((ref) async {
  return await ref.watch(settingsRepositoryProvider).telemetryOptIn();
});
