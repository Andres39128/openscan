import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Diálogo bloqueante con progreso x/y para tareas por página (OCR, export).
/// [task] recibe un notifier para reportar avance y devuelve el resultado.
/// Con `total` 0 muestra progreso indeterminado.
Future<T> runWithProgress<T>(
  BuildContext context,
  String label,
  int total,
  Future<T> Function(ValueNotifier<int> done) task,
) {
  final done = ValueNotifier<int>(0);
  final future = task(done);
  if (!context.mounted) {
    done.dispose();
    return future;
  }
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressBody(label: label, total: total, done: done),
    ),
  );
  return _awaitAndClose(context, future, done);
}

/// Espera [future] y cierra el diálogo siempre.
Future<T> _awaitAndClose<T>(
  BuildContext context,
  Future<T> future,
  ValueNotifier<int> done,
) async {
  try {
    return await future;
  } finally {
    done.dispose();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// Cuerpo del diálogo con barra de progreso.
class _ProgressBody extends StatelessWidget {
  /// Crea el cuerpo con etiqueta, total y avance.
  const new({
    required this.label,
    required this.total,
    required this.done,
  });

  /// Texto superior.
  final String label;

  /// Total de pasos (0 = indeterminado).
  final int total;

  /// Pasos completados.
  final ValueListenable<int> done;

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: done,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: total == 0 ? null : value / total,
                    ),
                    const SizedBox(height: 8),
                    Text(total == 0 ? '…' : '$value de $total'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
