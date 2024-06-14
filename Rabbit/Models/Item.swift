//
//  Item.swift
//  Rabbit
//
//  Created by Linus Rönnbäck Larsson on 2024-06-03.
//

import Foundation
import SwiftData

@Model
final class Logi {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
