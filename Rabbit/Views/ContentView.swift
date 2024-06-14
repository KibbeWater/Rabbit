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
    private var audioRecorder = PTTHandler()
    
    @State private var isVisionOpen: Bool = false
    @State private var isMicOpen: Bool = false
    
    @State private var currentlyPlaying: CurrentlyPlaying? = nil
    @State private var curPlaySink: AnyCancellable? = nil
    
    @State private var imgIdx = 0
    @State private var images = [String]()
    
    @State private var speechUnrecognized = false
    
    @State private var settingsOpen = false
    
    @Namespace private var animationNamespace
    
    // Tips
    private var visionTip = VisionTip()
    private var micTip = MicTip()
    
    private var ttsBlockTimer: Timer? = nil
    
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
                HStack {
                    Spacer()
                    Button {
                        settingsOpen.toggle()
                    } label: {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing)
                    }
                }
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
                        Image("Rabbit")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: !isVisionOpen && images.isEmpty ? 128 : 64)
                            .offset(y: isBouncing ? 5 : -5)
                            .onAppear {
                                withAnimation(.bounce()) {
                                    isBouncing.toggle()
                                }
                            }
                            .transition(.slide)
                            .id("rabbit")
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
                        withAnimation {
                            isMicOpen.toggle()
                        }
                    }, label: {
                        if !isMicOpen {
                            Image(systemName: "mic.fill")
                        } else {
                            Image(systemName: "mic.fill.badge.xmark")
                        }
                    })
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $settingsOpen, content: {
            SettingsPane(isOpen: $settingsOpen)
        })
        .task {
            await AVAudioApplication.requestRecordPermission()
            // Just initialize and cache thumbnail for quicker startups
            await model.camera.start()
            model.camera.stop()
        }
        .onChange(of: isMicOpen) { _, val in
            if !val {
                print("Stopped")
                audioRecorder.stopRecording { _buf in
                    if let buf = _buf {
                        sendBuf(buf)
                    }
                }
            } else {
                print("Started")
                audioRecorder.startRecording()
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
