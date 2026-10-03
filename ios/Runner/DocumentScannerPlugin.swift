import Flutter
import UIKit
import VisionKit

/// Bridge VisionKit (scan). Capa tonta: SDK → paths JPEG (RULES §2).
/// NO COMPILADO: requiere mac + Xcode (verificación pendiente en F2-iOS).
public class DocumentScannerPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
    private var pendingResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "dev.openscan/scan", binaryMessenger: registrar.messenger())
        let instance = DocumentScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "scanDocuments" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard pendingResult == nil else {
            result(FlutterError(code: "BUSY", message: "Scan en curso", details: nil))
            return
        }
        guard VNDocumentCameraViewController.isSupported else {
            result(FlutterError(code: "UNAVAILABLE", message: "VisionKit no soportado", details: nil))
            return
        }
        guard let root = Self.topViewController() else {
            result(FlutterError(code: "UNAVAILABLE", message: "Sin vista para presentar", details: nil))
            return
        }
        pendingResult = result
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        root.present(scanner, animated: true, completion: nil)
    }

    public func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        var paths: [String] = []
        for i in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: i)
            guard let data = image.jpegData(compressionQuality: 0.92) else { continue }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan_\(Int(Date().timeIntervalSince1970))_\(i).jpg")
            do {
                try data.write(to: url)
                paths.append(url.path)
            } catch {
                continue
            }
        }
        controller.dismiss(animated: true) { [weak self] in
            self?.pendingResult?(paths)
            self?.pendingResult = nil
        }
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.pendingResult?([])
            self?.pendingResult = nil
        }
    }

    public func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.pendingResult?(FlutterError(code: "UNAVAILABLE", message: error.localizedDescription, details: nil))
            self?.pendingResult = nil
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) else {
            return nil
        }
        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
