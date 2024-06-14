//
//  MicTip.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-13.
//

import Foundation
import TipKit

struct MicTip: Tip {
    static let chattedInVision = Event(id: "wsChatWithVision")
    
    var title: Text {
        Text("Use your mic for Vision prompts")
    }
    
    var message: Text? {
        Text("When prompting about Vision, you need to use your mic. Press to start a recording, then press again to finish recording.")
    }
    
    var image: Image? {
        Image(systemName: "mic")
    }
    
    var options: [any TipOption] {
        [
            IgnoresDisplayFrequency(true)
        ]
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.chattedInVision) {
                $0.donations.count > 0
            }
        ]
    }
}
