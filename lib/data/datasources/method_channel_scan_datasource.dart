import 'dart:async';
import 'package:flutter/services.dart';
import 'package:openscan/core/platform_bridge/channels.dart';
import 'package:openscan/core/result/app_failure.dart';
import 'package:openscan/data/datasources/scan_datasource.dart';

/// Bridge real al scanner nativo (implementación Swift/Kotlin en F2).
class MethodChannelScanDataSource implements ScanDataSource {
  /// Crea el bridge real (implementación nativa en F2).
  const new();

  @override
  Future<List<String>> scanDocuments() async {
    try {
      final paths = await scanChannel
          .invokeListMethod<String>('scanDocuments')
          .timeout(scanTimeout);
      return paths ?? [];
    } on PlatformException {
      throw const ScannerUnavailable();
    } on TimeoutException {
      throw const ScannerUnavailable();
    }
  }
}
