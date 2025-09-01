//
//  NetworkService.swift
//  augment-ios-interview-take-home
//
//  Created by Kiro on 9/1/25.
//

import Foundation

final class NetworkService: @unchecked Sendable {
    static let shared = NetworkService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.Config.requestTimeout
        config.timeoutIntervalForResource = APIConfiguration.Config.requestTimeout * 2
        self.session = URLSession(configuration: config)
    }
    
    func fetch<T: Codable>(_ type: T.Type, from url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.networkFailure(URLError(.badServerResponse))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw WeatherError.apiKeyInvalid
            case 404:
                throw WeatherError.cityNotFound("Location not found")
            case 429:
                throw WeatherError.apiQuotaExceeded
            default:
                throw WeatherError.networkFailure(URLError(.badServerResponse))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                return try decoder.decode(type, from: data)
            } catch {
                print("Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON: \(jsonString)")
                }
                throw WeatherError.malformedResponse
            }
            
        } catch let error as WeatherError {
            throw error
        } catch {
            throw WeatherError.networkFailure(error)
        }
    }
}