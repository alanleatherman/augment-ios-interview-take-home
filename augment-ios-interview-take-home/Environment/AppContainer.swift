//
//  AppContainer.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftUI
import CoreLocation

struct AppContainer {
    let appState: AppState
    let interactors: Interactors
    
    init(appState: AppState = AppState(), interactors: Interactors = .stub) {
        self.appState = appState
        self.interactors = interactors
    }
    
    struct Interactors {
        let weatherInteractor: WeatherInteractorProtocol
        let locationInteractor: LocationInteractorProtocol
        
        static var stub: Self {
            .init(
                weatherInteractor: StubWeatherInteractor(),
                locationInteractor: StubLocationInteractor()
            )
        }
    }
    
    static var preview: AppContainer {
        return MainActor.assumeIsolated {
            let appState = AppState()
            let weatherInteractor = WeatherInteractor(
                repository: WeatherPreviewRepository(),
                appState: appState
            )
            let locationInteractor = LocationInteractor(
                repository: LocationPreviewRepository(),
                appState: appState
            )
            
            let interactors = AppContainer.Interactors(
                weatherInteractor: weatherInteractor,
                locationInteractor: locationInteractor
            )
            
            return AppContainer(appState: appState, interactors: interactors)
        }
    }
    
    static var stub: AppContainer {
        return MainActor.assumeIsolated {
            let appState = AppState()
            return AppContainer(appState: appState, interactors: .stub)
        }
    }
    
    // MARK: - Coordinated Operations
    
    func refreshAllWeather() async {
        await interactors.weatherInteractor.refreshAllWeather()
    }
    
    @MainActor
    func clearAllData() async {
        await interactors.weatherInteractor.clearAllData()
        appState.weatherState.cities.removeAll()
        appState.weatherState.weatherData.removeAll()
        appState.weatherState.hourlyForecasts.removeAll()
        appState.weatherState.dailyForecasts.removeAll()
    }
    
    @MainActor
    func addCurrentLocationCity() async {
        // Set loading state at the beginning
        appState.locationState.isRequestingLocation = true
        
        // Clear any previous errors
        appState.weatherState.error = nil
        appState.locationState.locationError = nil
        
        defer {
            // Always clear loading state when done
            appState.locationState.isRequestingLocation = false
        }
        
        // First check if we already have current location cities and remove ALL of them
        let existingCurrentLocationCities = appState.weatherState.cities.filter { $0.isCurrentLocation }
        for existingCity in existingCurrentLocationCities {
            await interactors.weatherInteractor.removeCity(existingCity)
        }
        
        // Check current authorization status
        let currentStatus = appState.locationState.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            // Request permission for the first time
            await interactors.locationInteractor.requestLocationPermission()
            
            // Wait a moment for the permission dialog to be processed
            try? await Task.sleep(for: .milliseconds(500))
            
            // Check the result
            let newStatus = appState.locationState.authorizationStatus
            if newStatus == .denied || newStatus == .restricted {
                appState.weatherState.error = .locationPermissionDenied
                return
            } else if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Permission granted, proceed to get location
                await getCurrentLocationAndAddCity()
            }
            
        case .denied, .restricted:
            // Permission was previously denied, show error with guidance to settings
            appState.weatherState.error = .locationPermissionDenied
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission already granted, get location
            await getCurrentLocationAndAddCity()
            
        @unknown default:
            // Handle future cases
            appState.weatherState.error = .unknownError(LocationError.permissionDenied)
            return
        }
    }
    
    @MainActor
    private func getCurrentLocationAndAddCity() async {
        do {
            let location = try await interactors.locationInteractor.getCurrentLocation()
            print("📍 Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Use reverse geocoding to get the city name
            let (cityName, countryCode) = await getCityName(from: location)
            print("📍 Reverse geocoded to: \(cityName), \(countryCode)")
            
            // Create current location city with actual city name
            let currentLocationCity = City(
                name: cityName,
                countryCode: countryCode,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                isCurrentLocation: true
            )
            
            print("📍 Created current location city: \(currentLocationCity.name) at \(currentLocationCity.latitude), \(currentLocationCity.longitude)")
            
            // Add the city and fetch weather
            await interactors.weatherInteractor.addCity(currentLocationCity)
            
            // Switch to the newly added current location city
            if let newCityIndex = appState.weatherState.cities.firstIndex(where: { $0.isCurrentLocation }) {
                appState.weatherState.selectedCityIndex = newCityIndex
                print("📍 Switched to current location city at index: \(newCityIndex)")
            }
            
            // Start location monitoring for the new current location city
            startLocationMonitoringIfNeeded()
            
        } catch {
            print("❌ Error getting current location: \(error)")
            // Handle location error gracefully
            if let locationError = error as? LocationError {
                switch locationError {
                case .permissionDenied:
                    appState.weatherState.error = .locationPermissionDenied
                case .locationUnavailable(let underlyingError):
                    appState.weatherState.error = .networkFailure(underlyingError)
                case .timeout:
                    appState.weatherState.error = .networkFailure(locationError)
                }
            } else {
                appState.weatherState.error = .unknownError(error)
            }
        }
    }
    
    @MainActor
    private func getCityName(from location: CLLocation) async -> (cityName: String, countryCode: String) {
        let geocoder = CLGeocoder()
        
        do {
            print("🌍 Reverse geocoding location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let cityName = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? "Current Location"
                let countryCode = placemark.isoCountryCode ?? ""
                print("🌍 Reverse geocoding successful: \(cityName), \(countryCode)")
                return (cityName, countryCode)
            } else {
                print("🌍 No placemarks found")
            }
        } catch {
            print("🌍 Reverse geocoding failed: \(error)")
        }
        
        // Fallback to "Current Location" if geocoding fails
        print("🌍 Using fallback: Current Location")
        return ("Current Location", "")
    }
    
    @MainActor
    func handleAppDidBecomeActive() async {
        // Check if location permission status has changed when app becomes active
        // This is useful when user goes to Settings and enables location permission
        await interactors.locationInteractor.checkPermissionStatusAndRetry()
        
        // Start location monitoring if we have a current location city
        startLocationMonitoringIfNeeded()
    }
    
    @MainActor
    func startLocationMonitoringIfNeeded() {
        let hasCurrentLocationCity = appState.weatherState.cities.contains { $0.isCurrentLocation }
        if hasCurrentLocationCity {
            interactors.locationInteractor.startLocationMonitoring()
            
            // Set up notification observer for location updates
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("LocationUpdated"),
                object: nil,
                queue: .main
            ) { notification in
                if let updatedCity = notification.object as? City {
                    print("📍 Received LocationUpdated notification for: \(updatedCity.name)")
                    Task {
                        await self.interactors.weatherInteractor.handleLocationUpdate(for: updatedCity)
                    }
                } else {
                    print("📍 Received LocationUpdated notification but no city object")
                }
            }
        }
    }
    
    @MainActor
    func stopLocationMonitoring() {
        interactors.locationInteractor.stopLocationMonitoring()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("LocationUpdated"), object: nil)
    }
    
    @MainActor
    func navigateToCurrentLocationCity() async {
        // If user has permission and current location city exists, navigate to it
        if appState.locationState.hasLocationPermission {
            if let currentLocationIndex = appState.weatherState.cities.firstIndex(where: { $0.isCurrentLocation }) {
                // Navigate to existing current location city
                interactors.weatherInteractor.updateSelectedCityIndex(currentLocationIndex)
            } else {
                // No current location city exists, add one
                await addCurrentLocationCity()
            }
        } else {
            // No permission, request it
            await addCurrentLocationCity()
        }
    }
    
    @MainActor
    func handleAppDidEnterBackground() async {
        // Save the current selected city index when app goes to background
        // This ensures the user returns to the same city they were viewing
        let currentIndex = appState.weatherState.selectedCityIndex
        interactors.weatherInteractor.markCurrentCityAsHome()
        print("💾 App entering background - saved selected city index: \(currentIndex)")
    }
}

// MARK: - Environment Keys

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue = AppContainer(appState: AppState(), interactors: .stub)
}

private struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState()
}

private struct InteractorsKey: EnvironmentKey {
    static let defaultValue = AppContainer.Interactors.stub
}

// MARK: - Environment Values Extensions

extension EnvironmentValues {
    var container: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
    
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
    
    var interactors: AppContainer.Interactors {
        get { self[InteractorsKey.self] }
        set { self[InteractorsKey.self] = newValue }
    }
}

// MARK: - View Extension for Dependency Injection

extension View {
    func inject(_ container: AppContainer) -> some View {
        self.environment(\.container, container)
            .environment(\.appState, container.appState)
            .environment(\.interactors, container.interactors)
    }
}