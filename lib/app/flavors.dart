import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flavor de compilación (PLAN §3, RULES §5).
enum Flavor {
  /// Desarrollo: mocks, sin telemetría.
  dev,

  /// Staging: engines reales, icono beta.
  stg,

  /// Producción: lo que se sube a tiendas.
  prod,

  /// F-Droid: sin GMS (galería + sin OCR). Solo Android.
  oss,
}

/// Flavor activo, inyectado por entrypoint.
final flavorProvider = Provider<Flavor>((_) => throw UnimplementedError());

/// Config por flavor. Fuente única de diferencias entre ambientes.
extension FlavorConfig on Flavor {
  /// Nombre usado en `--flavor` y en título de la app.
  String get name => switch (this) {
        Flavor.dev => 'dev',
        Flavor.stg => 'stg',
        Flavor.prod => 'prod',
        Flavor.oss => 'oss',
      };

  /// Solo dev usa mocks. stg/prod usan bridges nativos (F2).
  bool get useMocks => this == Flavor.dev;

  /// Variante F-Droid sin GMS.
  bool get isOss => this == Flavor.oss;

  /// Título visible (dev/stg se distinguen a simple vista).
  String get appTitle => switch (this) {
        Flavor.dev => 'OpenScan dev',
        Flavor.stg => 'OpenScan stg',
        Flavor.prod => 'OpenScan',
        Flavor.oss => 'OpenScan oss',
      };
}
