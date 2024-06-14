//
//  SettingsPane.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-07.
//

import SwiftUI
import TipKit
import RabbitKit
import AVFoundation

struct SettingsPane: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var rabbitHole: RabbitHole
    
    @AppStorage("savedVol")
    private var savedVol: Double?
    
    @State var volume: Double = 0.5
    
    @Binding var isOpen: Bool
    
    var body: some View {
        List {
            Section(header: Text("General")) {
                VStack {
                    HStack {
                        Text("Volume")
                        
                        Slider(value: $volume, in: 0...3) {
                            Text("Volume")
                        } minimumValueLabel: {
                            Text("0%")
                        } maximumValueLabel: {
                            Text("100%")
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Account")) {
                Button("Open Rabbit Hole") {
                    openURL(URL(string: "https://hole.rabbit.tech")!)
                }
                .buttonStyle(.plain)
                Button("Reconnect") {
                    rabbitHole.reconnect()
                }
                .buttonStyle(.plain)
                Button("Log out", role: .destructive) {
                    isOpen.toggle()
                    rabbitHole.resetCredentials()
                    rabbitHole.reconnect()
                }
            }
            
            Section(header: Text("Permissions")) {
                // Camera allowed?
                switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
                case .restricted:
                    Text("Camera Authorized: Restricted")
                case .notDetermined:
                    Text("Camera Authorized: Not asked")
                case .denied:
                    Text("Camera Authorized: No")
                case .authorized:
                    Text("Camera Authorized: Yes")
                @unknown default:
                    Text("Camera Authorized: ERR")
                }
                
                // Mic allowed?
                switch AVAudioApplication.shared.recordPermission {
                case .undetermined:
                    Text("Mic Authorized: Not asked")
                case .denied:
                    Text("Mic Authorized: No")
                case .granted:
                    Text("Mic Authorized: Yes")
                @unknown default:
                    Text("Mic Authorized: ERR")
                }
            }
            
            Section(header: Text("Status")) {
                switch rabbitHole.wsStatus {
                case .connecting:
                    Text("Connection Status: Connecting...")
                case .open:
                    Text("Connection Status: Connected")
                case .closed:
                    Text("Connection Status: Closed")
                }
                Text("Authenticated: \(rabbitHole.isAuthenticated ? "Yes" : "No")")
            }
            .onAppear {
                rabbitHole.refreshStatus()
            }
        }
        .onChange(of: volume) { _, newVol in
            rabbitHole.rabbitPlayer.audioPlayer?.setVolume(
                Float(newVol),
                fadeDuration: 0.3
            )
            savedVol = newVol
        }
        .onAppear {
            if let _v = rabbitHole.rabbitPlayer.audioPlayer?.volume {
                volume = Double(_v)
            } else if let _v = savedVol {
                volume = _v
            }
        }
    }
}

#Preview {
    SettingsPane(isOpen: .constant(true))
        .environmentObject(
            RabbitHole(
                Config.shared.wsURL,
                autoConnect: false
            )
        )
}
