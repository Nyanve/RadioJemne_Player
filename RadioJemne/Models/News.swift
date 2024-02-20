//
//  News.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 13/02/2024.
//

import Foundation

struct News: Codable, Hashable {
    var title: String
    var summary: String
    var url: String
    var thumbnailURL: String 
    var datePublished: Date
}
