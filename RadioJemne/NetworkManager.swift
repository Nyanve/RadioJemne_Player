//
//  NetworkManger.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 06/02/2024.
//

import UIKit
class NetworkManger {
    
    let decoder = JSONDecoder()
    
    
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
        
        do {
            return try decoder.decode([Song].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}


enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}
