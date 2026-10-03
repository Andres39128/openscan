import 'package:shared_preferences/shared_preferences.dart';

/// Settings no sensibles (ARCHITECTURE §2). La key de DB jamás pasa por acá.
class SettingsRepository {
  /// Crea el repositorio.
  const new();

  static const _bioKey = 'biometric_lock';
  static const _telemetryKey = 'telemetry_opt_in';

  /// Bloqueo biométrico activo (default OFF).
  Future<bool> biometricLock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bioKey) ?? false;
  }

  /// Guarda preferencia de bloqueo biométrico.
  Future<void> setBiometricLock({required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bioKey, value);
  }

  /// Telemetría de crashes opt-in (default OFF).
  /// Sin SDK en F4: guarda consentimiento para F5 (Firebase).
  Future<bool> telemetryOptIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_telemetryKey) ?? false;
  }

  /// Guarda consentimiento de telemetría.
  Future<void> setTelemetryOptIn({required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_telemetryKey, value);
  }
}
