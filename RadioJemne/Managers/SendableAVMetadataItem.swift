//
//  SendableAVMetadataItem.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 20/02/2024.
//

import Foundation
import MediaPlayer

struct SendableAVMetadataItem {
    private let item: AVMetadataItem
    
    init(item: AVMetadataItem) {
        self.item = item
    }
    
    func loadValue() async throws -> String? {
        return try await item.load(.value) as? String
    }
}
