//
//  VisionTip.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-13.
//

import Foundation
import TipKit

struct VisionTip: Tip {
    static let messageEvent = Event(id: "wsChatEvent")
    
    var title: Text {
        Text("Try out Vision")
            .foregroundStyle(.accent)
    }
    
    var message: Text? {
        Text("Activate Vision and send a voice prompt asking about the Camera.")
    }
    
    var image: Image? {
        Image(systemName: "camera")
    }
    
    var rules: [Rule] {
        #Rule(Self.messageEvent) {
            $0.donations.count >= 3
        }
    }
    
    var options: [any TipOption] {
        [
            MaxDisplayCount(2)
        ]
    }
}
