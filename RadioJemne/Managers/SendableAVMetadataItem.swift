//
//  SendableAVMetadataItem.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 20/02/2024.
//

import Foundation
import MediaPlayer

struct SendableAVMetadataItem {
    let item: AVMetadataItem
    
    func loadValue() async throws -> String? {
        return try await self.item.load(.value) as? String
    }
}
