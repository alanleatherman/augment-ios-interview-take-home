//
//  LocationInteractor.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationInteractor: LocationInteractorProtocol {
    private let repository: LocationRepositoryProtocol
    private let appState: AppState
    
    // Observable state
    var isLoading = false
    var error: LocationError?
    
    init(repository: LocationRepositoryProtocol, appState: AppState) {
        self.repository = repository
        self.appState = appState
        
        // Initialize authorization status
        Task { @MainActor in
            appState.locationState.authorizationStatus = repository.getAuthorizationStatus()
        }
    }
    
    func requestLocationPermission() async {
        isLoading = true
        error = nil
        appState.locationState.isRequestingLocation = true
        appState.locationState.locationError = nil
        
        defer {
            isLoading = false
            // Note: Don't clear isRequestingLocation here as it's managed by AppContainer
        }
        
        // Get current status before request
        let initialStatus = repository.getAuthorizationStatus()
        
        // Only request if not determined
        if initialStatus == .notDetermined {
            await repository.requestLocationPermission()
            
            // Give the system a moment to process the permission dialog
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        // Update authorization status
        let newStatus = repository.getAuthorizationStatus()
        appState.locationState.authorizationStatus = newStatus
        
        // Set error if permission was denied or restricted
        if newStatus == .denied || newStatus == .restricted {
            let locationError = LocationError.permissionDenied
            self.error = locationError
            appState.locationState.locationError = locationError
        }
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        isLoading = true
        error = nil
        appState.locationState.locationError = nil
        
        defer {
            isLoading = false
            // Note: Don't clear isRequestingLocation here as it's managed by AppContainer
        }
        
        do {
            let location = try await repository.getCurrentLocation()
            
            // Update app state
            appState.locationState.currentLocation = location
            appState.locationState.authorizationStatus = repository.getAuthorizationStatus()
            
            return location
            
        } catch {
            let locationError = error as? LocationError ?? .locationUnavailable(error)
            self.error = locationError
            appState.locationState.locationError = locationError
            throw error
        }
    }
    
    nonisolated func checkLocationPermission() -> Bool {
        let status = repository.getAuthorizationStatus()
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        error = nil
        appState.locationState.locationError = nil
    }
    
    nonisolated func hasLocationPermission() -> Bool {
        // This can be called from any thread for quick checks
        return true // We'll implement this properly when needed
    }
    
    func retryLocationRequest() async {
        if error != nil {
            do {
                _ = try await getCurrentLocation()
            } catch {
                // Error is already handled in getCurrentLocation
            }
        }
    }
    
    func checkPermissionStatusAndRetry() async {
        // This method can be called when the app becomes active again
        // to check if the user has enabled location permission in Settings
        let currentStatus = repository.getAuthorizationStatus()
        appState.locationState.authorizationStatus = currentStatus
        
        // Clear previous errors if permission is now granted
        if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
            error = nil
            appState.locationState.locationError = nil
            appState.weatherState.error = nil
            
            // Start location monitoring if permission is granted
            startLocationMonitoring()
        } else {
            // Stop monitoring if permission is revoked
            stopLocationMonitoring()
        }
    }
    
    // MARK: - Location Monitoring
    
    nonisolated func startLocationMonitoring() {
        guard checkLocationPermission() else { return }
        
        repository.startLocationMonitoring { location in
            Task { @MainActor in
                await self.handleLocationUpdate(location)
            }
        }
    }
    
    nonisolated func stopLocationMonitoring() {
        repository.stopLocationMonitoring()
    }
    
    private func handleLocationUpdate(_ location: CLLocation) async {
        print("📍 Location update received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Update the current location in app state
        appState.locationState.currentLocation = location
        
        // Find current location city and update its weather
        if let currentLocationCity = appState.weatherState.cities.first(where: { $0.isCurrentLocation }) {
            print("📍 Found existing current location city: \(currentLocationCity.name)")
            
            // Update the city's coordinates if they've changed significantly
            let distance = CLLocation(latitude: currentLocationCity.latitude, longitude: currentLocationCity.longitude)
                .distance(from: location)
            
            print("📍 Distance from previous location: \(Int(distance))m")
            
            // Only update if the location has changed by more than 1km
            if distance > 1000 {
                print("📍 Location changed significantly (\(Int(distance))m), updating current location city")
                
                // Get updated city name through reverse geocoding
                Task { @MainActor in
                    let geocoder = CLGeocoder()
                    do {
                        let placemarks = try await geocoder.reverseGeocodeLocation(location)
                        let cityName = placemarks.first?.locality ?? placemarks.first?.subAdministrativeArea ?? placemarks.first?.administrativeArea ?? currentLocationCity.name
                        let countryCode = placemarks.first?.isoCountryCode ?? currentLocationCity.countryCode
                        
                        print("📍 Reverse geocoded new location to: \(cityName), \(countryCode)")
                        
                        // Create updated city with new coordinates and potentially new name
                        let updatedCity = City(
                            id: currentLocationCity.id,
                            name: cityName,
                            countryCode: countryCode,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            isCurrentLocation: true
                        )
                        
                        // Update the city in the cities array
                        if let index = appState.weatherState.cities.firstIndex(where: { $0.id == currentLocationCity.id }) {
                            appState.weatherState.cities[index] = updatedCity
                            print("📍 Updated city coordinates and name in app state")
                        }
                        
                        // Refresh weather for the updated location
                        NotificationCenter.default.post(
                            name: NSNotification.Name("LocationUpdated"),
                            object: updatedCity
                        )
                        print("📍 Posted LocationUpdated notification")
                        
                    } catch {
                        print("📍 Reverse geocoding failed, keeping existing city name: \(error)")
                        
                        // Create updated city with new coordinates but keep existing name
                        let updatedCity = City(
                            id: currentLocationCity.id,
                            name: currentLocationCity.name,
                            countryCode: currentLocationCity.countryCode,
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            isCurrentLocation: true
                        )
                        
                        // Update the city in the cities array
                        if let index = appState.weatherState.cities.firstIndex(where: { $0.id == currentLocationCity.id }) {
                            appState.weatherState.cities[index] = updatedCity
                            print("📍 Updated city coordinates in app state (kept existing name)")
                        }
                        
                        // Refresh weather for the updated location
                        NotificationCenter.default.post(
                            name: NSNotification.Name("LocationUpdated"),
                            object: updatedCity
                        )
                        print("📍 Posted LocationUpdated notification")
                    }
                }
            } else {
                print("📍 Location change not significant enough, skipping update")
            }
        } else {
            print("📍 No current location city found in app state")
        }
    }
}