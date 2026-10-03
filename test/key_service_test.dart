import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openscan/core/security/key_service.dart';

class _MockStorage extends Mock implements FlutterSecureStorage;

const _kKey = 'sqlcipher_key';

void main() {
  test('reutiliza la key existente sin escribir', () async {
    final storage = _MockStorage();
    when(() => storage.read(key: _kKey))
        .thenAnswer((_) async => 'existente');

    expect(await KeyService(storage).getOrCreateDbKey(), 'existente');
    verifyNever(
      () => storage.write(
        key: _kKey,
        value: any(named: 'value'),
      ),
    );
  });

  test('genera y guarda key de 32 bytes si no existe', () async {
    final storage = _MockStorage();
    when(() => storage.read(key: _kKey)).thenAnswer((_) async => null);
    when(
      () => storage.write(key: _kKey, value: any(named: 'value')),
    )
        .thenAnswer((_) async {});

    final key = await KeyService(storage).getOrCreateDbKey();
    expect(key.isNotEmpty, isTrue);
    verify(() => storage.write(key: _kKey, value: key)).called(1);
  });
}
