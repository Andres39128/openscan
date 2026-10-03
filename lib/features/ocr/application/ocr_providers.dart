import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/repositories/ocr_engine_impl.dart';
import 'package:openscan/domain/repositories/ocr_engine.dart';

/// Motor OCR activo (datasource según flavor).
/// Motor OCR activo (datasource según flavor).
final ocrEngineProvider = Provider<OcrEngine>(
  (ref) => OcrEngineImpl(ref.watch(ocrDataSourceProvider)),
);
