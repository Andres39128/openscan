import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/core/permissions/camera_permission.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/domain/entities/scanned_page.dart';
import 'package:openscan/features/scan/application/scan_providers.dart';

/// Escanea con permiso previo. null = denegado/cancelado/fallo (ya avisado).
Future<List<ScannedPage>?> scanWithPermission(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!await ensureCameraReady(context)) return null;
  try {
    return await ref.read(scanDocumentsProvider).call();
  } on Cancelled {
    return null;
  } on AppFailure {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner no disponible')),
    );
    return null;
  }
}
