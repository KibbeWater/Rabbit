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
    
    @State var proxyUrl: String = ""
    
    var rsgLink: AttributedString {
        var attributedString = try! AttributedString(markdown: "[rabbitserver-go](https://github.com/KibbeWater/rabbitserver-go)")
        attributedString.foregroundColor = .accent
        return attributedString
    }
    
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
            
            Section(header: Text("Proxy")) {
                HStack{
                    TextField("Proxy URL", text: $proxyUrl)
                    Button("Set") {
                        if let _url = URL(string: proxyUrl) {
                            Config.shared.setWsURL(_url)
                            rabbitHole.reconnect(_url)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canSetProxy(proxyUrl))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    Button("Reset") {
                        Config.shared.resetWsURL()
                        proxyUrl = ""
                        rabbitHole.reconnect(Config.shared.wsURL)
                    }
                    .buttonStyle(.bordered)
                }
                Text("Run your own instance of \(rsgLink)")
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
        .task {
            if Config.shared.isWsURLSet() {
                self.proxyUrl = Config.shared.wsURL.absoluteString
            }
        }
    }
    
    func canSetProxy(_ pUrl: String) -> Bool {
        guard let url = URL(string: pUrl) else { return false }
        return Config.shared.wsURL.absoluteString != url.absoluteString
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
