import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/app/auth_gate.dart';
import 'package:openscan/app/flavors.dart';
import 'package:openscan/app/router.dart';
import 'package:openscan/app/theme.dart';
import 'package:openscan/data/datasources/gallery_scan_datasource.dart';
import 'package:openscan/data/datasources/mock_ocr_datasource.dart';
import 'package:openscan/data/datasources/mock_scan_datasource.dart';
import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';
import 'package:openscan/data/repositories/no_ocr_engine.dart';
import 'package:openscan/features/ocr/application/ocr_providers.dart';

/// Arranque común a los 3 flavors.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        // dev: mocks. oss: fallback local sin GMS. stg/prod: bridges.
        if (flavor.useMocks) ...[
          scanDataSourceProvider.overrideWithValue(const MockScanDataSource()),
          ocrDataSourceProvider.overrideWithValue(const MockOcrDataSource()),
        ],
        if (flavor.isOss) ...[
          scanDataSourceProvider
              .overrideWithValue(const GalleryScanDataSource()),
          ocrEngineProvider.overrideWithValue(const NoOcrEngine()),
        ],
      ],
      child: const OpenScanApp(),
    ),
  );
}

/// Raíz: solo theme + router. Sin lógica.
/// Raíz: solo theme + router. Sin lógica.
class OpenScanApp extends ConsumerWidget {
  /// Crea la app raíz.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorProvider);
    return MaterialApp.router(
      title: flavor.appTitle,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: router,
      builder: (context, child) => AuthGate(
        child: child ?? const SizedBox(),
      ),
    );
  }
}
