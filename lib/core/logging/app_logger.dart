import 'dart:io';

/// Log rotativo local 3×1MB, sin PII ni secrets (ARCHITECTURE §8).
class AppLogger {
  /// Crea el logger sobre [_dir] (sandbox).
  const new(this._dir);

  final Directory _dir;

  /// Máximo por archivo antes de rotar.
  /// Máximo por archivo antes de rotar.
  static const int maxBytes = 1024 * 1024;

  /// Agrega una línea con timestamp UTC (IO sync: appends chicos).
  void log(String tag, String message) {
    final file = File('${_dir.path}/openscan_0.log');
    if (file.existsSync() && file.lengthSync() > maxBytes) _rotate();
    file.writeAsStringSync(
      '${DateTime.now().toUtc().toIso8601String()} [$tag] $message\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  /// Rota 0→1→2 (borra el más viejo).
  void _rotate() {
    final old = File('${_dir.path}/openscan_2.log');
    if (old.existsSync()) old.deleteSync();
    for (var i = 1; i >= 0; i--) {
      final src = File('${_dir.path}/openscan_$i.log');
      if (src.existsSync()) src.renameSync('${_dir.path}/openscan_${i + 1}.log');
    }
  }

  /// Archivos de log existentes (para exportar en Diagnóstico).
  List<File> logFiles() {
    final out = <File>[];
    for (var i = 0; i < 3; i++) {
      final f = File('${_dir.path}/openscan_$i.log');
      if (f.existsSync()) out.add(f);
    }
    return out;
  }
}
