package com.openscan.openscan

import android.app.Activity
import android.net.Uri
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** Bridge ML Kit Document Scanner. Capa tonta: SDK → paths JPEG (RULES §2). */
class MainActivity : FlutterFragmentActivity() {
    private var pendingResult: MethodChannel.Result? = null

    private val scannerLauncher =
        registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
            val res = pendingResult
            pendingResult = null
            if (res == null) return@registerForActivityResult
            if (result.resultCode != Activity.RESULT_OK || result.data == null) {
                // Cancelado por el usuario: lista vacía, no error (Cancelled en Dart).
                res.success(emptyList<String>())
                return@registerForActivityResult
            }
            try {
                val scanningResult = GmsDocumentScanningResult.fromActivityResultIntent(result.data!!)
                val paths = scanningResult?.pages?.mapNotNull { page ->
                    copyToSandbox(page.imageUri)
                } ?: emptyList()
                res.success(paths)
            } catch (e: Exception) {
                res.error("UNAVAILABLE", e.message, null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.openscan/scan")
            .setMethodCallHandler { call, result ->
                if (call.method != "scanDocuments") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("BUSY", "Scan en curso", null)
                    return@setMethodCallHandler
                }
                try {
                    val options = GmsDocumentScannerOptions.Builder()
                        .setGalleryImportAllowed(true)
                        .setPageLimit(100)
                        .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                        .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                        .build()
                    val client = GmsDocumentScanning.getClient(options)
                    pendingResult = result
                    // getStartScanIntent es async: devuelve Task<IntentSender>.
                    client
                        .getStartScanIntent(this)
                        .addOnSuccessListener { sender ->
                            val request = IntentSenderRequest.Builder(sender).build()
                            scannerLauncher.launch(request)
                        }
                        .addOnFailureListener { e ->
                            pendingResult = null
                            result.error("UNAVAILABLE", e.message, null)
                        }
                } catch (e: Exception) {
                    pendingResult = null
                    result.error("UNAVAILABLE", e.message, null)
                }
            }

    // Canal OCR latino on-device (F3). Coordenadas normalizadas 0..1.
    // ML Kit Latin no expone confianza por línea: conf 1.0 (PLAN §2).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.openscan/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("OCR_FAILED", "Sin path", null)
                    return@setMethodCallHandler
                }
                try {
                    val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                    val iw = image.width.toDouble()
                    val ih = image.height.toDouble()
                    TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        .process(image)
                        .addOnSuccessListener { text ->
                            val blocks = text.textBlocks
                                .flatMap { it.lines }
                                .mapNotNull { line ->
                                    val box = line.boundingBox ?: return@mapNotNull null
                                    mapOf(
                                        "text" to line.text,
                                        "x" to box.left / iw,
                                        "y" to box.top / ih,
                                        "w" to box.width() / iw,
                                        "h" to box.height() / ih,
                                        "conf" to 1.0,
                                    )
                                }
                            result.success(mapOf("fullText" to text.text, "blocks" to blocks))
                        }
                        .addOnFailureListener { e ->
                            result.error("OCR_FAILED", e.message, null)
                        }
                } catch (e: Exception) {
                    result.error("OCR_FAILED", e.message, null)
                }
            }
    }

    /** Copia el JPEG del scanner al sandbox (content:// → archivo propio). */
    private fun copyToSandbox(uri: Uri): String? {
        val input = contentResolver.openInputStream(uri) ?: return null
        val out = File(
            cacheDir,
            "scan_${System.currentTimeMillis()}_${(uri.lastPathSegment ?: "p").takeLast(8)}.jpg",
        )
        input.use { ins -> out.outputStream().use { outs -> ins.copyTo(outs) } }
        return out.absolutePath
    }
}
