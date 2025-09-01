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
    var temperatureUnit: TemperatureUnit = .fahrenheit // Default to Fahrenheit
    var refreshInterval: TimeInterval = 600 // 10 minutes
    var enableAutoRefresh = true
    var enableLocationServices = true
    
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