//
//  Song.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 06/02/2024.
//

import Foundation

struct Song: Codable, Hashable {
    var artist: String
    var title: String
    var date: Date
}
