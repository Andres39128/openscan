import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/app/flavors.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/features/library/application/library_providers.dart';
import 'package:openscan/features/library/presentation/home_page.dart';

void main() {
  testWidgets('muestra estado de DB y conteo', (tester) async {
    final db = AppDb.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.dev),
          appDbProvider.overrideWithValue(AsyncValue.data(db)),
          documentCountProvider.overrideWithValue(
            const AsyncValue.data(2),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.text('OpenScan dev'), findsOneWidget);
    expect(find.text('DB cifrada: OK'), findsOneWidget);
    expect(find.text('Documentos: 2'), findsOneWidget);
    expect(find.text('Escanear'), findsOneWidget);
  });
}
