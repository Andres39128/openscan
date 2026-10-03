import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Garantiza cámara antes del scan: rationale en contexto,
/// denegado permanente → ajustes (RULES §2). Nunca loop de pedido.
Future<bool> ensureCameraReady(BuildContext context) async {
  var status = await Permission.camera.status;
  if (status.isGranted || status.isLimited) return true;
  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cámara bloqueada'),
        content: const Text(
          'OpenScan necesita la cámara para escanear. '
          'Activala en ajustes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ABRIR AJUSTES'),
          ),
        ],
      ),
    );
    if (open == true) await openAppSettings();
    return false;
  }
  if (!context.mounted) return false;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Permiso de cámara'),
      content: const Text(
        'OpenScan usa la cámara solo para escanear documentos. '
        'Nada sale del teléfono.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('ESCANEAR'),
        ),
      ],
    ),
  );
  if (go != true) return false;
  status = await Permission.camera.request();
  return status.isGranted || status.isLimited;
}
