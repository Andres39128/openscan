package com.openscan.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Variante F-Droid sin GMS: bridges no disponibles, Dart usa fallback local. */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.openscan/scan")
            .setMethodCallHandler { call, result ->
                if (call.method == "scanDocuments") {
                    result.error("UNAVAILABLE", "Sin GMS en variante F-Droid", null)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.openscan/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method == "recognizeText") {
                    result.error("OCR_FAILED", "Sin GMS en variante F-Droid", null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
