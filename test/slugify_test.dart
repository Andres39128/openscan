import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/text/slugify.dart';

void main() {
  test('normaliza título a ASCII sin espacios', () {
    expect(slugify('Mi Factura 2026!'), 'mi_factura_2026');
    expect(slugify('  ___  '), 'escaneo');
  });

  test('nombre de archivo con patrón PLAN §2', () {
    expect(
      exportFileName('Mi Factura', DateTime(2026, 3, 5, 9, 7)),
      'openscan_mi_factura_20260305_0907.pdf',
    );
  });
}
