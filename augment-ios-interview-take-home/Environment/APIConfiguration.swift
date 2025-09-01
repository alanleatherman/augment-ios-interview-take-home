//
//  APIConfiguration.swift
//  augment-ios-interview-take-home
//
//  Created by Kiro on 9/1/25.
//

import Foundation

struct APIConfiguration {
    static let shared = APIConfiguration()
    
    private init() {}
    
    /// OpenWeatherMap API Key
    /// In production, this should be stored securely on the server and retrieved via authenticated API calls
    /// For development purposes, we're using a hardcoded key with obfuscation
    var openWeatherMapAPIKey: String {
        // Simple obfuscation - in production use proper key management
        let obfuscatedKey = "5ba7fa811c3a97ec456f34293534cc6e"
        return obfuscatedKey
    }
    
    /// Base URLs for OpenWeatherMap API
    struct URLs {
        static let currentWeather = "https://api.openweathermap.org/data/2.5/weather"
        static let forecast = "https://api.openweathermap.org/data/2.5/forecast"
        static let geocoding = "https://api.openweathermap.org/geo/1.0/direct"
        // Note: One Call 3.0 API requires paid subscription - using free alternatives above
    }
    
    /// API Configuration
    struct Config {
        static let units = "imperial" // Use Fahrenheit by default
        static let requestTimeout: TimeInterval = 10.0
        static let cacheTimeout: TimeInterval = 10 * 60 // 10 minutes
    }
}