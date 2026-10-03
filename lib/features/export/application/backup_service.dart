import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:openscan/core/result/app_failure.dart';

/// Backup cifrado E2E (RULES §7).
/// Formato: `[salt 16][nonce 12][ciphertext+tag AES-256-GCM]`.
/// Key: PBKDF2-HMAC-SHA256 600k iters (ARCHITECTURE §6). Nunca ZipCrypto.
class BackupService {
  /// Crea el servicio (sin estado).
  const new();

  /// Itera PBKDF2 del spec. Extraído para testear el formato, no el costo.
  static const pbkdf2Iterations = 600000;

  /// Empaqueta [sourceDir] cifrado con [password] en `outDir/*.enc`.
  Future<File> exportBackup({
    required Directory sourceDir,
    required String password,
    required Directory outDir,
  }) async {
    final zipBytes = _zipDir(sourceDir);
    final salt = _random(16);
    final nonce = _random(12);
    final key = await _derive(password, salt);
    try {
      final box = await AesGcm.with256bits().encrypt(
        zipBytes,
        secretKey: key,
        nonce: nonce,
      );
      final stamp = DateTime.now();
      String p(int n) => n.toString().padLeft(2, '0');
      final name = 'openscan_backup_${stamp.year}${p(stamp.month)}'
          '${p(stamp.day)}_${p(stamp.hour)}${p(stamp.minute)}.enc';
      final out = File('${outDir.path}/$name');
      await out.writeAsBytes(
        [...salt, ...nonce, ...box.cipherText, ...box.mac.bytes],
        flush: true,
      );
      return out;
    } finally {
      key.destroy();
    }
  }

  /// Restaura un `.enc` en [targetDir]. Password mal → [BackupFailed].
  /// Rechaza paths absolutos y `..` (zip-slip).
  Future<int> restoreBackup({
    required File backup,
    required String password,
    required Directory targetDir,
  }) async {
    final raw = await backup.readAsBytes();
    if (raw.length < 16 + 12 + 16 + 1) throw const BackupFailed();
    final salt = raw.sublist(0, 16);
    final nonce = raw.sublist(16, 28);
    final cipherAndTag = raw.sublist(28);
    final cipherText = cipherAndTag.sublist(0, cipherAndTag.length - 16);
    final tag = cipherAndTag.sublist(cipherAndTag.length - 16);
    final key = await _derive(password, salt);
    late Uint8List zipBytes;
    try {
      zipBytes = Uint8List.fromList(
        await AesGcm.with256bits().decrypt(
          SecretBox(
            cipherText,
            nonce: nonce,
            mac: Mac(tag),
          ),
          secretKey: key,
        ),
      );
    } on SecretBoxAuthenticationError {
      throw const BackupFailed();
    } finally {
      key.destroy();
    }
    final archive = ZipDecoder().decodeBytes(zipBytes);
    var count = 0;
    for (final f in archive.files) {
      if (!f.isFile || f.name.isEmpty) continue;
      if (f.name.startsWith('/') || f.name.contains('..')) {
        throw const BackupFailed();
      }
      final dest = File('${targetDir.path}/${f.name}');
      await dest.parent.create(recursive: true);
      await dest.writeAsBytes(f.content as List<int>, flush: true);
      count++;
    }
    return count;
  }

  /// PBKDF2-HMAC-SHA256 → key AES-256.
  Future<SecretKey> _derive(String password, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }

  /// Zip recursivo con paths relativos POSIX.
  Uint8List _zipDir(Directory dir) {
    final archive = Archive();
    for (final e in dir.listSync(recursive: true)) {
      if (e is! File) continue;
      final rel =
          e.path.substring(dir.path.length + 1).replaceAll(r'\', '/');
      if (rel.isEmpty) continue;
      archive.addFile(
        ArchiveFile(rel, e.lengthSync(), e.readAsBytesSync()),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Bytes aleatorios seguros.
  Uint8List _random(int n) => Uint8List.fromList(
        List<int>.generate(n, (_) => Random.secure().nextInt(256)),
      );
}
