//
//  RegisterView.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-04.
//

import SwiftUI
import VisionKit
import RabbitKit

struct RegisterView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var rabbitHole: RabbitHole
    
    @State private var isBouncing = false
    
    @State var isShowingScanner = false
    @State private var scannedUrl: URL?
    
    @State private var manualLogin: Bool = false
    
    @State private var imeiInput: String = ""
    @State private var accountKeyInput: String = ""
    
    @AppStorage("disclaimerShown")
    private var disclaimerShown: Bool = false
    
    @State private var isDisclaimerShown: Bool = false
    
    var rbtHoleLink: AttributedString {
        var attributedString = try! AttributedString(markdown: "[hole.rabbit.tech](https://hole.rabbit.tech/)")
        attributedString.foregroundColor = .accent
        return attributedString
    }
    
    var body: some View {
        VStack {
            Spacer()
            Image("Rabbit")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 128)
                .offset(y: isBouncing ? 5 : -5)
                .onAppear {
                    withAnimation(.bounce()) {
                        isBouncing.toggle()
                    }
                }
                .id("rabbit")
            Spacer()
            if !manualLogin {
                VStack(spacing: 12) {
                    Button("Scan QR Code") {
                        isShowingScanner = true
                    }
                    .buttonStyle(.borderedProminent)
                    .fullScreenCover(isPresented: $isShowingScanner) {
                        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                            GeometryReader { _ in
                                ZStack(alignment: .bottom) {
                                    DataScannerRepresentable(
                                        shouldStartScanning: $isShowingScanner,
                                        recognizedUrl: $scannedUrl,
                                        dataToScanFor: [.barcode(symbologies: [.qr])]
                                    )
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 25.0))
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .onChange(of: scannedUrl) { _, new in
                        guard let url = new else { return }
                        if url.host() != "hole.rabbit.tech" && url.path() != "/apis/linkDevice" {
                            print("Invalid URL")
                            return
                        }
                        
                        rabbitHole.register(url)
                        
                        isShowingScanner = false
                    }
                    Text("OR")
                        .fontWeight(.semibold)
                    Button("Sign in Manually") {
                        withAnimation {
                            manualLogin.toggle()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .transition(.blurReplace)
            } else {
                VStack {
                    Text("Advanced Sign-in")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    TextField("IMEI", text: $imeiInput)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .disabled(rabbitHole.isAuthenticating || !rabbitHole.canAuthenticate)
                    TextField("Account Key", text: $accountKeyInput)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .disabled(rabbitHole.isAuthenticating || !rabbitHole.canAuthenticate)
                    HStack {
                        Button {
                            rabbitHole.signIn(imei: imeiInput, accountKey: accountKeyInput)
                        } label: {
                            Spacer()
                            Text("Sign in")
                            Spacer()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(imeiInput.isEmpty || accountKeyInput.isEmpty || rabbitHole.isAuthenticating || !rabbitHole.canAuthenticate)
                        
                        Button {
                            withAnimation {
                                manualLogin.toggle()
                            }
                        } label: {
                            Spacer()
                            Text("Cancel")
                            Spacer()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, 24)
                .transition(.blurReplace)
            }
            Spacer()
            HStack(spacing: 6) {
                Text("Register at \(rbtHoleLink)")
                Spacer()
            }
            .font(.footnote)
            .padding(.horizontal, 24)
        }
        .onAppear {
            guard disclaimerShown == false else { return }
            
            isDisclaimerShown = true
        }
        .sheet(isPresented: $isDisclaimerShown, onDismiss: {
            disclaimerShown = true
        }, content: {
            VStack {
                Text("Disclaimer")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.bottom, 24)
                VStack(alignment: .leading, spacing: 18) {
                    Text("By using and registering for this app, you acknowledge and accept that your account is at risk of being banned at any time without warning.")
                    .fixedSize(horizontal: false, vertical: true)
                    Text("The app and its developers are not liable for any consequences resulting from an account ban, including but not limited to loss of access to your account, data, or any other associated losses.")
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 32)
                    Text("By proceeding with registration and usage of this app, you confirm that you have read, understood, and agree to this disclaimer and all related policies. If you do not agree with these terms, please discontinue use of the app immediately.")
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                Spacer()
                Button("I Acknowledge") {
                    disclaimerShown = true
                    isDisclaimerShown = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical)
        })
    }
}

#Preview {
    RegisterView()
        .environmentObject(RabbitHole(Config.shared.wsURL))
}
