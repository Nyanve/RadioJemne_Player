//
//  NetworkManager.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 06/02/2024.
//

import UIKit
import SwiftyXMLParser

class NetworkManager {
    
    let decoder = JSONDecoder()
    let dateFormatter = DateFormatter()
    
    func getSongHistory() async throws -> [Song] {
        let endpoint = "https://www.radiomelody.sk/wp-json/radio/v1/playlist"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode([Song].self, from: data)
        } catch {
            debugPrint("Decode error", error)
            throw NetworkError.decodingError
        }
    }
    
    func getNews() async throws -> [News] {
        let endpoint = "https://www.radiomelody.sk/feed/"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let xml = XML.parse(data)
        
        var newsArray: [News] = []
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        
        for item in xml["rss", "channel", "item"] {
            guard let title = item["title"].text,
                  let url = item["link"].text,
                  let dateString = item["pubDate"].text,
                  let datePublished = dateFormatter.date(from: dateString),
                  let summaryCDATA = item["description"].element?.CDATA,
                  let summary = String(data: summaryCDATA, encoding: .utf8),
                  let thumbnailURL = item["media:thumbnail"].attributes["url"] ?? nil
            else {
                throw NetworkError.invalidData
            }
            
            let news = News(title: title, summary: summary, url: url, thumbnailURL: thumbnailURL, datePublished: datePublished)
            newsArray.append(news)
        }
        
        return newsArray
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case invalidData
}
