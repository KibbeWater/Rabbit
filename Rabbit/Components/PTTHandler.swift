//
//  PTTHandler.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-04.
//

import SwiftUI
import AVFoundation

class PTTHandler {
    var audioRecorder: AVAudioRecorder?
    var audioURL: URL?

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
            // Set the file URL for saving the recording
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "recordedAudio.wav"
            audioURL = documentsPath.appendingPathComponent(fileName)
            
            // Set up audio settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Initialize the audio recorder
            audioRecorder = try AVAudioRecorder(url: audioURL!, settings: settings)
            audioRecorder?.record()
            
        } catch {
            print("Error setting up recording session: \(error.localizedDescription)")
        }
    }
    
    func stopRecording(completion: @escaping (Data?) -> Void) {
        audioRecorder?.stop()
        
        guard let url = audioURL else {
            print("No audio URL found")
            completion(nil)
            return
        }
        
        // Delay reading the audio file
        do {
            // Read the recorded audio file
            let audioData = try Data(contentsOf: url)
            completion(audioData)
        } catch {
            print("Error reading audio file: \(error.localizedDescription)")
            completion(nil)
        }
    }
}
