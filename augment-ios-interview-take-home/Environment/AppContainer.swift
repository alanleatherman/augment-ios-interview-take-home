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
        appState.locationState.isRequestingLocation = true
        
        appState.weatherState.error = nil
        appState.locationState.locationError = nil
        
        defer {
            appState.locationState.isRequestingLocation = false
        }
        
        let existingCurrentLocationCities = appState.weatherState.cities.filter { $0.isCurrentLocation }
        for existingCity in existingCurrentLocationCities {
            await interactors.weatherInteractor.removeCity(existingCity)
        }
        
        let currentStatus = appState.locationState.authorizationStatus
        
        switch currentStatus {
        case .notDetermined:
            await interactors.locationInteractor.requestLocationPermission()
            
            // Wait a moment for the permission dialog to be processed
            try? await Task.sleep(for: .milliseconds(500))
            
            let newStatus = appState.locationState.authorizationStatus
            if newStatus == .denied || newStatus == .restricted {
                appState.weatherState.error = .locationPermissionDenied
                return
            } else if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                await getCurrentLocationAndAddCity()
            }
            
        case .denied, .restricted:
            appState.weatherState.error = .locationPermissionDenied
            return
            
        case .authorizedWhenInUse, .authorizedAlways:
            await getCurrentLocationAndAddCity()
            
        @unknown default:
            appState.weatherState.error = .unknownError(LocationError.permissionDenied)
            return
        }
    }
    
    @MainActor
    private func getCurrentLocationAndAddCity() async {
        do {
            let location = try await interactors.locationInteractor.getCurrentLocation()
            print("📍 Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            let (cityName, countryCode) = await getCityName(from: location)
            print("📍 Reverse geocoded to: \(cityName), \(countryCode)")
            
            let currentLocationCity = City(
                name: cityName,
                countryCode: countryCode,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                isCurrentLocation: true
            )
            
            print("📍 Created current location city: \(currentLocationCity.name) at \(currentLocationCity.latitude), \(currentLocationCity.longitude)")
            
            await interactors.weatherInteractor.addCity(currentLocationCity)
            
            if let newCityIndex = appState.weatherState.cities.firstIndex(where: { $0.isCurrentLocation }) {
                appState.weatherState.selectedCityIndex = newCityIndex
                print("📍 Switched to current location city at index: \(newCityIndex)")
            }
            
            startLocationMonitoringIfNeeded()
            
        } catch {
            print("❌ Error getting current location: \(error)")

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
        
        // Fallback to Current Location
        print("🌍 Using fallback: Current Location")
        return ("Current Location", "")
    }
    
    @MainActor
    func handleAppDidBecomeActive() async {
        let previousStatus = appState.locationState.authorizationStatus
        await interactors.locationInteractor.checkPermissionStatusAndRetry()
        let currentStatus = appState.locationState.authorizationStatus
        
        if (previousStatus == .denied || previousStatus == .notDetermined) &&
           (currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways) {
            await addCurrentLocationCity()
        }
        
        startLocationMonitoringIfNeeded()
    }
    
    @MainActor
    func startLocationMonitoringIfNeeded() {
        let hasCurrentLocationCity = appState.weatherState.cities.contains { $0.isCurrentLocation }
        if hasCurrentLocationCity {
            interactors.locationInteractor.startLocationMonitoring()
            
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
        if appState.locationState.hasLocationPermission {
            if let currentLocationIndex = appState.weatherState.cities.firstIndex(where: { $0.isCurrentLocation }) {
                interactors.weatherInteractor.updateSelectedCityIndex(currentLocationIndex)
            } else {
                await addCurrentLocationCity()
            }
        } else {
            // No permission, request it
            await addCurrentLocationCity()
        }
    }
    
    @MainActor
    func handleAppDidEnterBackground() async {
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
