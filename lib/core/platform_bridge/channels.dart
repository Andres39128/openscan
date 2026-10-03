import 'package:flutter/services.dart';

/// Nombres de canal nativo. La capa nativa es tonta:
/// mapea SDK → DTO (RULES §2).
/// Canal al scanner nativo (solo JPEG).
const scanChannel = MethodChannel('dev.openscan/scan');
/// Canal al OCR nativo.
const ocrChannel = MethodChannel('dev.openscan/ocr');

/// Timeouts con cancelación (RULES §1).
/// Timeout de captura con cancelación.
const scanTimeout = Duration(seconds: 15);
/// Timeout de OCR con cancelación.
const ocrTimeout = Duration(seconds: 10);
