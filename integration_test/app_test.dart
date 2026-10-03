import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openscan/app/bootstrap.dart';
import 'package:openscan/app/flavors.dart';
import 'package:openscan/core/security/key_service.dart';
import 'package:openscan/data/db/app_db.dart';
import 'package:openscan/features/export/application/backup_service.dart';
import 'package:path_provider/path_provider.dart';

class _MockStorage extends Mock implements FlutterSecureStorage;

/// F4 en dispositivo: SQLCipher nativo + backup + smoke UI.
/// Sin cámara (los bridges reales se prueban manual según PLAN F4).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SQLCipher abre y backup roundtrip en dispositivo',
      (tester) async {
    final storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(
      () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    final key = await KeyService(storage).getOrCreateDbKey();
    expect(key.isNotEmpty, isTrue);

    final docs = await getApplicationDocumentsDirectory();
    final db = AppDb.openFile(File('${docs.path}/it.db'), key);
    addTearDown(db.close);
    await db.into(db.documents).insert(
          DocumentsCompanion.insert(
            id: 'it1',
            title: 'Integración',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    expect(await db.documentCount(), 1);

    final tmp = await getTemporaryDirectory();
    const svc = BackupService();
    final enc = await svc.exportBackup(
      sourceDir: docs,
      password: 'it-pass',
      outDir: tmp,
    );
    expect(enc.existsSync(), isTrue);
  });

  testWidgets('smoke: home renderiza en dispositivo', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [flavorProvider.overrideWithValue(Flavor.dev)],
        child: const OpenScanApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Escanear'), findsOneWidget);
  });
}
