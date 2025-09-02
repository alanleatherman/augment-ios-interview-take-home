//
//  APIConfiguration.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import Foundation

struct APIConfiguration {
    static let shared = APIConfiguration()
    
    private init() {}
    
    /// OpenWeatherMap API Key
    /// Uses secure key management from APIKeys configuration
    var openWeatherMapAPIKey: String {
        return APIKeys.openWeatherMapAPIKey
    }
    
    /// Base URLs for OpenWeatherMap API (Free options)
    struct URLs {
        static let currentWeather = "https://api.openweathermap.org/data/2.5/weather"
        static let forecast = "https://api.openweathermap.org/data/2.5/forecast"
        static let geocoding = "https://api.openweathermap.org/geo/1.0/direct"
    }
    
    /// API Configuration
    struct Config {
        static let units = "imperial" // Use Fahrenheit by default
        static let requestTimeout: TimeInterval = 10.0
        static let cacheTimeout: TimeInterval = 10 * 60 // 10 minutes
    }
}
