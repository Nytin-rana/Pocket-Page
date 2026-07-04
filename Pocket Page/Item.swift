//
//  Item.swift
//  Pocket Page
//
//  Created by Nytin Rana on 04/07/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
