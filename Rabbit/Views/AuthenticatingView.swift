//
//  AuthenticatingView.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-05.
//

import SwiftUI
import RabbitKit

struct AuthenticatingView: View {
    @EnvironmentObject var rabbitHole: RabbitHole
    
    var body: some View {
        VStack {
            Spacer()
            Image("Rabbit")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 128)
                .id("rabbit")
            Spacer()
            if rabbitHole.isAuthenticating {
                Text("Signing in to RabbitHole")
                    .font(.title)
                Text("Please hold")
                    .font(.title3)
                    .padding(.bottom)
            } else {
                Text("Connection failed")
                    .font(.title)
                Button("Retry") {
                    rabbitHole.reconnect()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
            Button("Cancel Login") {
                rabbitHole.resetCredentials()
            }
            .buttonStyle(.bordered)
            .padding(.bottom)
        }
    }
}

#Preview {
    AuthenticatingView()
        .environmentObject(
            RabbitHole(
                Config.shared.wsURL,
                autoConnect: false
            )
        )
}
