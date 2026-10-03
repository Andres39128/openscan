import 'dart:async';
import 'package:flutter/services.dart';
import 'package:openscan/core/platform_bridge/channels.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/data/datasources/ocr_datasource.dart';
import 'package:openscan/data/datasources/ocr_dto.dart';

/// Bridge real al OCR nativo (implementación Swift/Kotlin en F2).
class MethodChannelOcrDataSource implements OcrDataSource {
  /// Crea el bridge real (implementación nativa en F2).
  const new();

  @override
  Future<OcrResultDto> recognizeText(
    String imagePath,
    List<String> langs,
  ) async {
    try {
      final raw = await ocrChannel.invokeMapMethod<String, Object?>(
        'recognizeText',
        {'path': imagePath, 'langs': langs},
      ).timeout(ocrTimeout);
      if (raw == null) throw const OcrFailed();
      return OcrResultDto.fromMap(Map<String, Object?>.from(raw));
    } on PlatformException {
      throw const OcrFailed();
    } on TimeoutException {
      throw const OcrFailed();
    }
  }
}
