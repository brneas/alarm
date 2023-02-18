import Flutter
import UIKit
import AVFoundation

public class SwiftAlarmPlugin: NSObject, FlutterPlugin {
    var someDict = [Int: SwiftAlarmPlugin]()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.gdelataillade/alarm", binaryMessenger: registrar.messenger())
    let instance = SwiftAlarmPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public var audioPlayer: AVAudioPlayer!

  private func setUpAudio() {
    try! AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
    try! AVAudioSession.sharedInstance().setActive(true)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let args = call.arguments as! Dictionary<String, Any>
      print(args["alarmId"] as! Int)
      
      var thisSelf = self
      let alarmId = args["alarmId"] as! Int
      let hasKey = someDict[alarmId] != nil
      if(hasKey){
          thisSelf = someDict[alarmId] as! SwiftAlarmPlugin
      }
      else{
          someDict[alarmId] = SwiftAlarmPlugin()
      }
      print(someDict)
      
    DispatchQueue.global(qos: .default).async {
      if call.method == "setAlarm" {
          thisSelf.setAlarm(call: call, result: result, thisSelf: thisSelf)
      } else if call.method == "stopAlarm" {
        if thisSelf.audioPlayer != nil {
            thisSelf.audioPlayer.stop()
            thisSelf.audioPlayer = nil
          result(true)
        }
        result(false)
      } else if call.method == "audioCurrentTime" {
        if thisSelf.audioPlayer != nil {
          result(Double(thisSelf.audioPlayer.currentTime))
        } else {
          result(0.0)
        }
      } else {
        DispatchQueue.main.sync {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

    private func setAlarm(call: FlutterMethodCall, result: FlutterResult, thisSelf: SwiftAlarmPlugin) {
        thisSelf.setUpAudio()

    let args = call.arguments as! Dictionary<String, Any>
    let assetAudio = args["assetAudio"] as! String
    let delayInSeconds = args["delayInSeconds"] as! Double
    let loopAudio = args["loopAudio"] as! Bool

    if let audioPath = Bundle.main.path(forResource: assetAudio, ofType: nil) {
      let audioUrl = URL(fileURLWithPath: audioPath)
      do {
          thisSelf.audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
      } catch {
        result(FlutterError.init(code: "NATIVE_ERR", message: "[Alarm] Error loading AVAudioPlayer with given asset path or url", details: nil))
      }
    } else {
      result(FlutterError.init(code: "NATIVE_ERR", message: "[Alarm] Error with audio file: path is \(assetAudio)", details: nil))
    }

    let currentTime = thisSelf.audioPlayer.deviceCurrentTime
    let time = currentTime + delayInSeconds

    if loopAudio {
        thisSelf.audioPlayer.numberOfLoops = -1
    }

        thisSelf.audioPlayer.prepareToPlay()
        thisSelf.audioPlayer.play(atTime: time)

    result(true)
  }
}
