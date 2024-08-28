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
    // var audioURL: URL?

    func startRecording() -> URL? {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
            // Set the file URL for saving the recording
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "recordedAudio.wav"
            let audioURL = documentsPath.appendingPathComponent(fileName)
            
            // Set up audio settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Initialize the audio recorder
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.record()
            
            return audioURL
        } catch {
            print("Error setting up recording session: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func stopRecording(_ url: URL, completion: @escaping (Data?) -> Void) {
        audioRecorder?.stop()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Delay reading the audio file
            do {
                // Read the recorded audio file
                let audioData = try Data(contentsOf: url)
                completion(audioData)
                
                // Remove the file
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch {
                print("Error reading audio file: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
