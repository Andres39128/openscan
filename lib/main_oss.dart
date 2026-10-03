import 'package:openscan/app/bootstrap.dart';
import 'package:openscan/app/flavors.dart';

/// Entrypoint flavor oss: variante F-Droid sin GMS (solo Android).
Future<void> main() => bootstrap(Flavor.oss);
