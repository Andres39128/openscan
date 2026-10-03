import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dueño de la key AES-256 de SQLCipher (ARCHITECTURE §6).
/// Vive solo en Keychain/Keystore. Jamás en prefs, logs ni backups.
class KeyService {
  /// Crea el servicio sobre [_storage] (Keychain/Keystore).
  new(this._storage);

  final FlutterSecureStorage _storage;

  static const _keyName = 'sqlcipher_key';

  /// Devuelve la key existente o genera+guarda una nueva (32 bytes, base64).
  Future<String> getOrCreateDbKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = base64UrlEncode(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    await _storage.write(key: _keyName, value: fresh);
    return fresh;
  }
}
