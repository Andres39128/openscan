import 'package:openscan/app/bootstrap.dart';
import 'package:openscan/app/flavors.dart';

/// Entrypoint flavor prod: lo que se sube a tiendas.
Future<void> main() => bootstrap(Flavor.prod);
