import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/domain/entities/ocr_result.dart';
import 'package:openscan/features/ocr/application/ocr_results_provider.dart';

void main() {
  test('put/clear del cache', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    expect(c.read(ocrResultsProvider), isEmpty);
    c
        .read(ocrResultsProvider.notifier)
        .put('p1', const OcrResult(fullText: 'a', blocks: []));
    expect(c.read(ocrResultsProvider).containsKey('p1'), isTrue);
    c.read(ocrResultsProvider.notifier).clear();
    expect(c.read(ocrResultsProvider), isEmpty);
  });
}
