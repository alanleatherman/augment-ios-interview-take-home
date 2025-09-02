//
//  AppState.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

@Observable
class AppState {
    var weatherState = WeatherState()
    var locationState = LocationState()
    var appSettings = AppSettings()
}

@Observable
class WeatherState {
    var cities: [City] = []
    var weatherData: [UUID: Weather] = [:]
    var hourlyForecasts: [UUID: [HourlyWeather]] = [:]
    var dailyForecasts: [UUID: [DailyWeather]] = [:]
    var isLoading = false
    var error: WeatherError?
    var lastRefresh: Date?
    var selectedCityIndex: Int = 0 // Track the currently selected city
    
    // Computed properties
    var citiesWithWeather: [(City, Weather?)] {
        cities.map { city in
            (city, weatherData[city.id])
        }
    }
    
    var hasData: Bool {
        !cities.isEmpty
    }
    
    var isEmpty: Bool {
        cities.isEmpty
    }
}

@Observable
class LocationState {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isRequestingLocation = false
    var locationError: LocationError?
    
    var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var canRequestLocation: Bool {
        authorizationStatus == .notDetermined
    }
}

@Observable
class AppSettings {
    // Use UserDefaults for persistence
    private let userDefaults = UserDefaults.standard
    
    // Temperature unit with persistence
    var temperatureUnit: TemperatureUnit {
        get {
            let rawValue = userDefaults.string(forKey: "temperatureUnit") ?? TemperatureUnit.fahrenheit.rawValue
            return TemperatureUnit(rawValue: rawValue) ?? .fahrenheit
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "temperatureUnit")
        }
    }
    
    // Refresh interval with persistence
    var refreshInterval: TimeInterval {
        get {
            let interval = userDefaults.double(forKey: "refreshInterval")
            return interval > 0 ? interval : 600 // Default to 10 minutes
        }
        set {
            userDefaults.set(newValue, forKey: "refreshInterval")
        }
    }
    
    // Auto refresh setting with persistence
    var enableAutoRefresh: Bool {
        get {
            // Default to true if not set
            return userDefaults.object(forKey: "enableAutoRefresh") as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: "enableAutoRefresh")
        }
    }
    
    // Location services setting with persistence
    var enableLocationServices: Bool {
        get {
            // Default to true if not set
            return userDefaults.object(forKey: "enableLocationServices") as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: "enableLocationServices")
        }
    }
    
    // Last selected city index with persistence - THIS IS THE KEY FIX
    var lastSelectedCityIndex: Int {
        get {
            return userDefaults.integer(forKey: "lastSelectedCityIndex") // Defaults to 0
        }
        set {
            userDefaults.set(newValue, forKey: "lastSelectedCityIndex")
            print("💾 Persisted selected city index: \(newValue)")
        }
    }
    
    // Home city ID with persistence
    var homeCityId: UUID? {
        get {
            guard let uuidString = userDefaults.string(forKey: "homeCityId") else { return nil }
            return UUID(uuidString: uuidString)
        }
        set {
            if let uuid = newValue {
                userDefaults.set(uuid.uuidString, forKey: "homeCityId")
                print("💾 Persisted home city ID: \(uuid)")
            } else {
                userDefaults.removeObject(forKey: "homeCityId")
                print("💾 Cleared home city ID")
            }
        }
    }
    
    enum TemperatureUnit: String, CaseIterable, Sendable {
        case celsius = "metric"
        case fahrenheit = "imperial"
        
        var displayName: String {
            switch self {
            case .celsius: return "Celsius"
            case .fahrenheit: return "Fahrenheit"
            }
        }
        
        var symbol: String {
            switch self {
            case .celsius: return "°C"
            case .fahrenheit: return "°F"
            }
        }
    }
}