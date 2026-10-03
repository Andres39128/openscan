import Flutter
import UIKit
import Vision

/// Bridge Vision OCR on-device (VNRecognizeTextRequest).
/// Sin lógica de negocio: mapea observaciones → DTO.
/// Coordenadas Vision (origen abajo-izq) se voltean a arriba-izq (contrato).
/// NO COMPILADO: requiere mac + Xcode (verificación pendiente en F3-iOS).
public class OcrPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "dev.openscan/ocr", binaryMessenger: registrar.messenger())
        let instance = OcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "recognizeText" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "OCR_FAILED", message: "Sin path", details: nil))
            return
        }
        let langs = (args["langs"] as? [String] ?? ["es"]).map { lang -> String in
            lang == "es" ? "es-ES" : (lang == "en" ? "en-US" : lang)
        }
        guard let image = UIImage(contentsOfFile: path),
              let cgImage = image.cgImage else {
            result(FlutterError(code: "OCR_FAILED", message: "Imagen ilegible", details: nil))
            return
        }

        let request = VNRecognizeTextRequest { req, error in
            if error != nil {
                result(FlutterError(code: "OCR_FAILED", message: "Vision falló", details: nil))
                return
            }
            let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
            var full: [String] = []
            var blocks: [[String: Any]] = []
            for obs in observations {
                guard let top = obs.topCandidates(1).first else { continue }
                full.append(top.string)
                let box = obs.boundingBox
                blocks.append([
                    "text": top.string,
                    "x": box.origin.x,
                    // Vision origina abajo-izquierda: voltear Y.
                    "y": 1.0 - box.origin.y - box.size.height,
                    "w": box.size.width,
                    "h": box.size.height,
                    "conf": Double(top.confidence),
                ])
            }
            result(["fullText": full.joined(separator: "\n"), "blocks": blocks])
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = langs
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                result(FlutterError(code: "OCR_FAILED", message: "Vision falló", details: nil))
            }
        }
    }
}
