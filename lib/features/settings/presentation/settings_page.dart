import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/core/logging/app_logger.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/features/export/application/backup_service.dart';
import 'package:openscan/features/settings/application/settings_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Ajustes F4: bloqueo, telemetría (consentimiento), diagnóstico,
/// backup cifrado y restore.
class SettingsPage extends ConsumerWidget {
  /// Crea la pantalla de ajustes.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bio = ref.watch(biometricLockProvider);
    final telemetry = ref.watch(telemetryOptInProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          bio.when(
            data: (v) => SwitchListTile(
              title: const Text('Bloqueo biométrico'),
              subtitle: const Text('Pide biometría al abrir y al volver'),
              value: v,
              onChanged: (next) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .setBiometricLock(value: next);
                ref.invalidate(biometricLockProvider);
              },
            ),
            loading: () => const ListTile(title: Text('Bloqueo…')),
            error: (_, _) => const ListTile(title: Text('Bloqueo: error')),
          ),
          telemetry.when(
            data: (v) => SwitchListTile(
              title: const Text('Telemetría de crashes'),
              subtitle: const Text(
                'Opt-in. Sin SDK en F4: guarda consentimiento para F5.',
              ),
              value: v,
              onChanged: (next) async {
                await ref
                    .read(settingsRepositoryProvider)
                    .setTelemetryOptIn(value: next);
                ref.invalidate(telemetryOptInProvider);
              },
            ),
            loading: () => const ListTile(title: Text('Telemetría…')),
            error: (_, _) =>
                const ListTile(title: Text('Telemetría: error')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Exportar diagnóstico'),
            subtitle: const Text('Comparte los logs locales'),
            onTap: () => _shareLogs(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Crear backup cifrado'),
            subtitle: const Text('Zip AES-256-GCM con tu password'),
            onTap: () => _backup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restaurar backup'),
            subtitle: const Text('Pide reiniciar la app'),
            onTap: () => _restore(context),
          ),
        ],
      ),
    );
  }

  /// Comparte los logs rotativos locales.
  Future<void> _shareLogs(BuildContext context, WidgetRef ref) async {
    final dir = await getApplicationDocumentsDirectory();
    final files = AppLogger(dir).logFiles();
    if (files.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin logs todavía')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path)],
        text: 'Diagnóstico OpenScan',
      ),
    );
  }

  /// Pide password y comparte el .enc.
  Future<void> _backup(BuildContext context) async {
    final password = await _askPassword(context, 'Password del backup');
    if (password == null || password.isEmpty || !context.mounted) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final tmp = await getTemporaryDirectory();
      final file = await const BackupService().exportBackup(
        sourceDir: docs,
        password: password,
        outDir: tmp,
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Backup OpenScan'),
      );
    } on AppFailure {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el backup')),
      );
    }
  }

  /// Elige .enc, pide password y restaura sobre el sandbox.
  Future<void> _restore(BuildContext context) async {
    final picked = await FilePicker.pickFiles(
      allowedExtensions: ['enc'],
    );
    final path = picked.isNotEmpty ? picked.first.path : null;
    if (path == null || !context.mounted) return;
    final password = await _askPassword(context, 'Password del backup');
    if (password == null || password.isEmpty || !context.mounted) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final n = await const BackupService().restoreBackup(
        backup: File(path),
        password: password,
        targetDir: docs,
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup restaurado'),
          content: Text('$n archivos. Reiniciá la app.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ENTENDIDO'),
            ),
          ],
        ),
      );
    } on AppFailure {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup inválido o password mal')),
      );
    }
  }

  /// Diálogo de password (nunca se guarda).
  Future<String?> _askPassword(BuildContext context, String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    ).then((v) {
      controller.dispose();
      return v;
    });
  }
}
