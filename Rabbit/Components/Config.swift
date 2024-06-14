//
//  Config.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-14.
//

import Foundation

public struct Config {
    public static let shared = Config()
    
    public var wsURL: URL {
        URL(string: "wss://r1.lrlnet.se/ws")!
    }
}
