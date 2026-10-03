import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:openscan/features/settings/application/settings_providers.dart';

/// Puerta biométrica: bloquea la UI hasta autenticar (PLAN §2).
/// Solo si el setting está activo. Re-bloquea al volver de fondo.
class AuthGate extends ConsumerStatefulWidget {
  /// Crea la puerta sobre [child].
  const new({required this.child, super.key});

  /// Contenido protegido.
  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  bool? _unlocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _unlocked == true) {
      setState(() => _unlocked = null);
      unawaited(_check());
    }
  }

  /// Si el lock está apagado, pasa directo. Si no, autentica.
  Future<void> _check() async {
    final enabled =
        await ref.read(settingsRepositoryProvider).biometricLock();
    if (!enabled) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }
    await _auth();
  }

  /// Autenticación biométrica del sistema (sin PIN propio).
  Future<void> _auth() async {
    var ok = false;
    try {
      ok = await LocalAuthentication().authenticate(
        localizedReason: 'Desbloquear OpenScan',
        biometricOnly: true,
      );
    } on Object catch (_) {
      ok = false;
    }
    if (mounted) setState(() => _unlocked = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked == true) return widget.child;
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 48),
            const SizedBox(height: 16),
            const Text('OpenScan bloqueado'),
            const SizedBox(height: 16),
            if (_unlocked == null)
              const CircularProgressIndicator()
            else
              FilledButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: const Text('Desbloquear'),
                onPressed: _auth,
              ),
          ],
        ),
      ),
    );
  }
}
