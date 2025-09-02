//
//  NetworkService.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
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
            print("🌐 Making network request to: \(url.absoluteString)")
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw WeatherError.networkFailure(URLError(.badServerResponse))
            }
            
            print("🌐 HTTP Status Code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Successful HTTP response")
                break
            case 401:
                print("❌ API Key Invalid (401)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Error response: \(jsonString)")
                }
                throw WeatherError.apiKeyInvalid
            case 404:
                print("❌ Location not found (404)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Error response: \(jsonString)")
                }
                throw WeatherError.cityNotFound("Location not found")
            case 429:
                print("❌ API quota exceeded (429)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Error response: \(jsonString)")
                }
                throw WeatherError.apiQuotaExceeded
            default:
                print("❌ HTTP error: \(httpResponse.statusCode)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Error response: \(jsonString)")
                }
                throw WeatherError.networkFailure(URLError(.badServerResponse))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let result = try decoder.decode(type, from: data)
                print("✅ Successfully decoded response")
                return result
            } catch {
                print("❌ Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON: \(jsonString)")
                }
                throw WeatherError.malformedResponse
            }
            
        } catch let error as WeatherError {
            throw error
        } catch {
            print("❌ Network error: \(error)")
            throw WeatherError.networkFailure(error)
        }
    }
}
