//
//  ContentView.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-03.
//

import SwiftUI
import SwiftData
import RabbitKit
import VisionKit
import AVFAudio
import Combine
import TipKit
import UIKit

extension Animation {
    static func bounce() -> Animation {
        Animation
            .easeInOut(duration: 1)
            .repeatForever(autoreverses: true)
    }
}

struct ContentView: View {
    @EnvironmentObject var rabbitHole: RabbitHole
    
    @State private var isBouncing = false
    @State var message: String = ""
    @FocusState var chatIsFocused: Bool
    
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")
    @StateObject private var model = DataModel()
    @State private var audioRecorder = PTTHandler()
    
    @State private var isVisionOpen: Bool = false
    @State private var isMicOpen: Bool = false
    @State private var audioURL: URL?
    
    @State private var currentlyPlaying: CurrentlyPlaying? = nil
    @State private var curPlaySink: AnyCancellable? = nil
    
    @State private var imgIdx = 0
    @State private var images = [String]()
    
    @State private var speechUnrecognized = false
    
    @Namespace private var animationNamespace
    
    // Tips
    private var visionTip = VisionTip()
    private var micTip = MicTip()
    private var micHoldTip = MicHoldTip()
    
    private var ttsBlockTimer: Timer? = nil
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    let notificationFeedback = UINotificationFeedbackGenerator()
    
    func sendBuf(_ buf: Data?) -> Void {
        guard let recordedBuffer = buf else { return }
        
        rabbitHole.sendPTT(true)
        rabbitHole.sendAudio(recordedBuffer)
        let _image = model.viewfinderImage
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let image = _image, isVisionOpen {
                let imageRendering = ImageRenderer(content: image)
                rabbitHole.sendPTT(
                    false,
                    image: imageRendering.uiImage?.jpegData(compressionQuality: 0.5)
                )
                micTip.invalidate(reason: .actionPerformed)
            } else {
                rabbitHole.sendPTT(false)
            }
        }
    }
    
    func startRollingImages() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if imgIdx + 1 < images.count {
                startRollingImages()
                withAnimation {
                    imgIdx += 1
                }
            } else {
                withAnimation {
                    imgIdx = 0
                    images.removeAll()
                }
            }
        }
    }
    
    func getImage() -> URL? {
        if imgIdx < images.count {
            return URL(string: images[imgIdx])
        }
        return nil
    }
    
    var chatbox: some View {
        VStack {
            if let msg = currentlyPlaying?.audio.text?.chars.joined(separator: "") {
                HStack {
                    HStack {
                        Text(msg)
                            .transition(
                                .move(edge: .top)
                                .combined(with: .opacity)
                            )
                    }
                    .matchedGeometryEffect(id: "text", in: animationNamespace)
                        
                    if isVisionOpen {
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .id("chatbox")
        .matchedGeometryEffect(id: "chatbox", in: animationNamespace)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    if isVisionOpen {
                        GeometryReader { geo in
                            ViewfinderView(image:  $model.viewfinderImage )
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 25.0)
                        )
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                        .frame(maxWidth: .infinity, maxHeight: isVisionOpen ? .infinity : 0)
                        .onAppear {
                            Task {
                                await model.camera.start()
                            }
                        }
                        .onDisappear {
                            model.camera.stop()
                        }
                    }
                    
                    if !images.isEmpty {
                        GeometryReader { geo in
                            if let img = getImage() {
                                AsyncImage(url: img) { imgz in
                                    imgz
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }

                            }
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 25.0)
                        )
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                        .frame(maxWidth: .infinity, maxHeight: !images.isEmpty ? .infinity : 0)
                    }
                    
                    Spacer()
                    TipView(micTip)
                    HStack {
                        if !rabbitHole.isMeetingActive {
                            HStack(spacing: 24) {
                                Image("Rabbit")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: !isVisionOpen && images.isEmpty ? isMicOpen ? 128*0.8 : 128 : isMicOpen ? 64*0.8 : 64)
                                    .offset(y: isBouncing ? 5 : -5)
                                    .onAppear {
                                        withAnimation(.bounce()) {
                                            isBouncing.toggle()
                                        }
                                    }
                                    .transition(.slide)
                                    .id("rabbit")
                                if isMicOpen {
                                    Image(systemName: "mic")
                                        .font(.system(size: 82))
                                }
                            }
                        } else {
                            Image(systemName: "recordingtape")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: !isVisionOpen && images.isEmpty ? 128 : 64)
                                .transition(.slide)
                                .symbolEffect(.pulse, options: .repeat(.max))
                                .id("rabbit")
                        }
                        if isVisionOpen || !images.isEmpty {
                            chatbox
                                .padding(.leading)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    if !isVisionOpen && images.isEmpty {
                        Spacer()
                        chatbox
                    }
                }
                HStack {
                    if !rabbitHole.isMeetingActive {
                        TextField("Chat", text: $message)
                            .focused($chatIsFocused)
                            .transition(.blurReplace)
                        Button("Submit") {
                            guard !message.isEmpty else { return }
                            
                            let msg = message
                            message = ""
                            self.rabbitHole.sendText(msg)
                            VisionTip.messageEvent.sendDonation()
                            if isVisionOpen {
                                MicTip.chattedInVision.sendDonation()
                            }
                            
                            chatIsFocused = false
                        }
                        .buttonStyle(.borderedProminent)
                        .transition(.blurReplace)
                        
                        
                        Button("Vision") {
                            visionTip.invalidate(reason: .actionPerformed)
                            withAnimation {
                                isVisionOpen.toggle()
                            }
                        }
                        .popoverTip(visionTip)
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            guard isMicOpen else {
                                MicHoldTip.micNotHeld.sendDonation()
                                return
                            }
                            notificationFeedback.notificationOccurred(.success)
                            micHoldTip.invalidate(reason: .actionPerformed)
                            withAnimation {
                                isMicOpen = false
                            }
                        }, label: {
//                            if #available(iOS 18, *) {
//                                Image(
//                                    systemName:
//                                        !isMicOpen ?
//                                    "microphone.fill" : "microphone.slash.fill"
//                                )
//                                .contentTransition(.symbolEffect(
//                                    .replace.magic(
//                                        fallback: .downUp.byLayer
//                                    )
//                                ))
//                            } else {
                                Image(
                                    systemName:
                                        !isMicOpen ?
                                    "mic.fill" : "mic.slash.fill"
                                )
                            // }
                        })
                        .popoverTip(micHoldTip)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.2)
                                .onEnded({ _ in
                                    impactFeedback.impactOccurred()
                                    withAnimation {
                                        isMicOpen = true
                                    }
                                })
                        )
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            withAnimation {
                                isMicOpen = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                rabbitHole.stopMeeting()
                            }
                        } label: {
                            Text("End Voice Recording")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(!isMicOpen)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .task {
            await AVAudioApplication.requestRecordPermission()
            // Just initialize and cache thumbnail for quicker startups
            await model.camera.start()
            model.camera.stop()
        }
        .onChange(of: isMicOpen) { _, val in
            if !val {
                print("Stopped recording")
                guard audioURL != nil else { return }
                audioRecorder.stopRecording(audioURL!) { _buf in
                    if let buf = _buf {
                        sendBuf(buf)
                    }
                }
            } else {
                print("Started")
                if let url = audioRecorder.startRecording() {
                    audioURL = url
                } else {
                    isMicOpen = false
                }
            }
        }
        .onChange(of: rabbitHole.lastImages, { _, val in
            if isVisionOpen {
                withAnimation {
                    isVisionOpen.toggle()
                }
            }
            withAnimation {
                images = rabbitHole.lastImages
                imgIdx = 0
            }
            startRollingImages()
        })
        .onChange(of: isVisionOpen, { _, new in
            if !images.isEmpty && new {
                images.removeAll()
                imgIdx = 0
            }
        })
        .onChange(of: rabbitHole.isMeetingActive, { _, isMeetingActive in
            guard isMeetingActive else { return }
            isMicOpen.toggle()
        })
        .task {
            curPlaySink = rabbitHole.rabbitPlayer.$curPlaying.sink { curPlaying in
                withAnimation {
                    currentlyPlaying = curPlaying
                }
            }
        }
    }
    
    func imageToData(image: SwiftUI.Image) -> Data? {
        // Convert SwiftUI.Image to UIImage
        let uiImage = UIImage(systemName: "swift") // Replace with your image rendering logic

        // Check if the UIImage is created successfully
        guard let renderedImage = uiImage else {
            return nil
        }

        // Convert UIImage to PNG Data
        let pngData = renderedImage.pngData()
        return pngData
    }
}

#Preview {
    ContentView()
        .environmentObject(RabbitHole(Config.shared.wsURL))
}
