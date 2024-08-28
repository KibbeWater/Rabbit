//
//  MicHoldTip.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 28/8/24.
//

import Foundation
import TipKit

struct MicHoldTip: Tip {
    static let micNotHeld = Event(id: "wsMicNotHeld")
    
    var title: Text {
        Text("Talk to Rabbit")
    }
    
    var message: Text? {
        Text("Press and Hold the mic icon to start talking with your Rabbit.")
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
            #Rule(Self.micNotHeld) {
                $0.donations.count > 0
            }
        ]
    }
}
