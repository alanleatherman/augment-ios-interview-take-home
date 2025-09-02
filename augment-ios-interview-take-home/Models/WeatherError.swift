//
//  WeatherError.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation

// MARK: - Weather Errors

enum WeatherError: LocalizedError, Sendable, Equatable {
    case locationPermissionDenied
    case networkFailure(Error)
    case apiKeyInvalid
    case cityNotFound(String)
    case persistenceFailure(Error)
    case apiQuotaExceeded
    case malformedResponse
    case cacheExpired
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .locationPermissionDenied:
            return "Location access is required to show weather for your current location. Please enable location access in Settings > Privacy & Security > Location Services."
        case .networkFailure:
            return "Unable to connect to weather service. Please check your internet connection."
        case .apiKeyInvalid:
            return "Weather service configuration error. Please try again later."
        case .cityNotFound(let cityName):
            return "Weather data not available for \(cityName)"
        case .persistenceFailure:
            return "Failed to save weather data locally"
        case .apiQuotaExceeded:
            return "Weather service temporarily unavailable. Please try again in a few minutes."
        case .malformedResponse:
            return "Received invalid weather data. Please try again."
        case .cacheExpired:
            return "Weather data is outdated. Refreshing..."
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoveryAction: String? {
        switch self {
        case .locationPermissionDenied:
            return "Open Settings"
        case .networkFailure, .apiQuotaExceeded:
            return "Try again"
        case .cityNotFound:
            return "Remove city"
        case .cacheExpired:
            return "Refresh"
        default:
            return "Retry"
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: WeatherError, rhs: WeatherError) -> Bool {
        switch (lhs, rhs) {
        case (.locationPermissionDenied, .locationPermissionDenied):
            return true
        case (.apiKeyInvalid, .apiKeyInvalid):
            return true
        case (.apiQuotaExceeded, .apiQuotaExceeded):
            return true
        case (.malformedResponse, .malformedResponse):
            return true
        case (.cacheExpired, .cacheExpired):
            return true
        case (.cityNotFound(let lhsCity), .cityNotFound(let rhsCity)):
            return lhsCity == rhsCity
        case (.networkFailure, .networkFailure):
            return true // We'll consider all network failures equal for testing
        case (.persistenceFailure, .persistenceFailure):
            return true // We'll consider all persistence failures equal for testing
        case (.unknownError, .unknownError):
            return true // We'll consider all unknown errors equal for testing
        default:
            return false
        }
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError, Sendable, Equatable {
    case permissionDenied
    case locationUnavailable(Error)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .locationUnavailable(let error):
            return "Unable to get location: \(error.localizedDescription)"
        case .timeout:
            return "Location request timed out"
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied):
            return true
        case (.timeout, .timeout):
            return true
        case (.locationUnavailable, .locationUnavailable):
            return true // We'll consider all location unavailable errors equal for testing
        default:
            return false
        }
    }
}