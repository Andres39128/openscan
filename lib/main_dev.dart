import 'package:openscan/app/bootstrap.dart';
import 'package:openscan/app/flavors.dart';

/// Entrypoint flavor dev: engines mockeados, sin telemetría.
Future<void> main() => bootstrap(Flavor.dev);
