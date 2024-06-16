//
//  Config.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-14.
//

import Foundation
import SwiftUI

struct DefaultsKeys {
    static let wsUrl = "websocketUrl"
}

public struct Config {
    public static let shared = Config()

    private let defaultWsURL = URL(string: "wss://r1.lrlnet.se/ws")!
    @State public var wsURL: URL
    
    func setWsURL(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: DefaultsKeys.wsUrl)
        wsURL = url
    }
    
    func isWsURLSet() -> Bool {
        if wsURL.absoluteString == defaultWsURL.absoluteString {
            return false
        }
        return true
    }
    
    func resetWsURL() {
        setWsURL(defaultWsURL)
    }
    
    init() {
        if let _urlStr = UserDefaults.standard.string(forKey: DefaultsKeys.wsUrl),
           let _url = URL(string: _urlStr) {
            wsURL = _url
        } else {
            wsURL = defaultWsURL
        }
    }
}
