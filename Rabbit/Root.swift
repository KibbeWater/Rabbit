//
//  RabbitApp.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-03.
//

import TipKit
import SwiftUI
import SwiftData
import RabbitKit

@main
struct RabbitApp: App {
    @StateObject private var rabbitHole = RabbitHole(Config.shared.wsURL)
    
    @AppStorage("savedVol")
    private var savedVol: Double?
    
    @AppStorage("disclaimerShown")
    private var disclaimerShown: Bool = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            /* Item.self, */
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if (!rabbitHole.hasCredentials && !rabbitHole.isAuthenticated) || !disclaimerShown {
                    RegisterView()
                } else if rabbitHole.isAuthenticated {
                    ContentView()
                } else {
                    AuthenticatingView()
                        .transition(.opacity)
                }
            }
            .task {
                if let _savedVol = savedVol {
                    rabbitHole.rabbitPlayer.audioPlayer?.setVolume(
                        Float(_savedVol),
                        fadeDuration: 0.2
                    )
                }
            }
        }
        .environmentObject(rabbitHole)
        .modelContainer(sharedModelContainer)
    }
}
