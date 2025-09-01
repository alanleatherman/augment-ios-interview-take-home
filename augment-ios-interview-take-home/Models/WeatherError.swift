//
//  WeatherError.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation

// MARK: - Weather Errors

enum WeatherError: LocalizedError, Sendable {
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
            return "Location access is required to show weather for your current location"
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
            return "Enable location access in Settings"
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
}

// MARK: - Location Errors

enum LocationError: LocalizedError, Sendable {
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
}