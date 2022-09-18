//
//  HapticManager.swift
//  Feel Your Photo (iOS)
//
//  Created by Melody Yoon on 9/02/22.
//

import CoreHaptics
import AVFoundation

class HapticManager: ObservableObject {
    private var hapticEngine: CHHapticEngine? = nil
    private var hapticPlayer: CHHapticAdvancedPatternPlayer? = nil
    private var audioPlayer:AVAudioPlayer? = nil
    private var hapticON: Bool = false
    
    init() {
        createAudioPlayer("vibration")
        
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        guard hapticCapability.supportsHaptics else {
            print("Device does not support Haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
        } catch let error {
            print("Haptic engine not created: \(error)")
        }
        
        createHapticPlayer()
    }
    
    func createHapticPlayer() {
        let haptic = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 4.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: 0,
            duration: 60)
        
        do {
            let pattern = try CHHapticPattern(events: [haptic], parameters: [])
            hapticPlayer = try hapticEngine!.makeAdvancedPlayer(with: pattern)
        } catch let error {
            print("hapticEngine makeAdvancedPlayer: \(error)")
        }
    }
    
    func startHapticPlayer(density: Float) {
        var logDensity: Float
        /*if (density > 2) {logDensity = 4}
        else if (density > 1) {logDensity = 2}
        else if (density > 0.5) {logDensity = 1}
        else if (density > 0.25) {logDensity = 0.5}
        else {logDensity = 0.25}*/
        logDensity = density
        
        if ((hapticEngine) != nil) {
            let intensity = CHHapticDynamicParameter(
                parameterID: .hapticIntensityControl,
                value: logDensity,
                relativeTime: 0)
            
            do {
                if (hapticON == false) {
                    try hapticEngine!.start()
                    try hapticPlayer?.start(atTime: CHHapticTimeImmediate)
                }
                try hapticPlayer?.sendParameters([intensity], atTime: CHHapticTimeImmediate)
                hapticON = true
            } catch {
                print("hapticPlayer start error: \(error)")
            }
        }
        if (hapticEngine == nil) {
            audioPlayer?.setVolume(logDensity/2, fadeDuration: 0.1)
            //print(audioPlayer?.duration, audioPlayer?.currentTime)
            if (audioPlayer?.isPlaying == false) { audioPlayer?.play() }
        }
    }
    
    func stopHapticPlayer() {
        hapticON = false
        if ((hapticEngine) != nil) {
            do {
                try hapticPlayer?.stop(atTime: CHHapticTimeImmediate)
            } catch {
                print("hapticPlayer stop error: \(error)")
            }
        }
        audioPlayer?.setVolume(0.0, fadeDuration: 0.1)
        /*
        if stopPlayer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.audioPlayer?.stop()
                print("stop() audioPlayer")
            }
        }*/
    }
    
    func createAudioPlayer (_ soundfile: String) {
        if let path = Bundle.main.path(forResource: soundfile, ofType: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.prepareToPlay()
                audioPlayer?.numberOfLoops = 3
            } catch {
                print("Error: try AVAudioPlayer()")
            }
        } else {
            print("Error: createAudioPlayer(): file not found")
        }
    }
}
