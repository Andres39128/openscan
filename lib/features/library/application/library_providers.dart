import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openscan/core/security/key_service.dart';
import 'package:openscan/data/db/app_db.dart';

/// Key AES-256 del Keychain/Keystore.
final keyServiceProvider = Provider<KeyService>(
  (ref) => KeyService(const FlutterSecureStorage()),
);

/// DB cifrada abierta (una por sesión).
final appDbProvider = FutureProvider<AppDb>((ref) async {
  final key = await ref.watch(keyServiceProvider).getOrCreateDbKey();
  return await AppDb.openDefault(key);
});

/// Cantidad de documentos para la home.
final documentCountProvider = FutureProvider<int>((ref) async {
  final db = await ref.watch(appDbProvider.future);
  return await db.documentCount();
});
