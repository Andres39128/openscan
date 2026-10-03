import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Bridge VisionKit (NO COMPILADO en Linux: verificar en mac).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DocumentScannerPlugin") {
      DocumentScannerPlugin.register(with: registrar)
    }
    // Bridge Vision OCR (NO COMPILADO en Linux: verificar en mac).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OcrPlugin") {
      OcrPlugin.register(with: registrar)
    }
  }
}
