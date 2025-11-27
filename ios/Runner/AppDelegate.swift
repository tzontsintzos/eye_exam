import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var volumeChannel: FlutterMethodChannel?
  private var volumeView: MPVolumeView?
  private var isResettingVolume = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    volumeChannel = FlutterMethodChannel(name: "com.example.eye_exam/volume", binaryMessenger: controller.binaryMessenger)

    // Hide the system volume HUD
    volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    controller.view.addSubview(volumeView!)

    // Setup audio session
    do {
      try AVAudioSession.sharedInstance().setActive(true)
      try AVAudioSession.sharedInstance().setCategory(.ambient)
    } catch {
      print("Audio session error: \(error)")
    }

    // Set initial volume to middle
    setSystemVolume(0.5)

    // Observe volume changes
    AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.new, .old], context: nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "outputVolume" {
      // Ignore volume changes caused by our own reset
      if isResettingVolume {
        return
      }

      guard let newVolume = change?[.newKey] as? Float,
            let oldVolume = change?[.oldKey] as? Float,
            newVolume != oldVolume else { return }

      if newVolume > oldVolume {
        volumeChannel?.invokeMethod("volumeUp", arguments: nil)
      } else {
        volumeChannel?.invokeMethod("volumeDown", arguments: nil)
      }

      // Reset volume to middle to allow continuous button presses
      isResettingVolume = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        self.setSystemVolume(0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          self.isResettingVolume = false
        }
      }
    }
  }

  private func setSystemVolume(_ volume: Float) {
    if let slider = volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider {
      slider.value = volume
    }
  }

  deinit {
    AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
  }
}
