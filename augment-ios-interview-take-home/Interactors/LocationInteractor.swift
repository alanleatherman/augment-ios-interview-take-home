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
    }
    
    func requestLocationPermission() async {
        isLoading = true
        error = nil
        appState.locationState.isRequestingLocation = true
        appState.locationState.locationError = nil
        
        await repository.requestLocationPermission()
        
        // Update authorization status
        appState.locationState.authorizationStatus = repository.getAuthorizationStatus()
        appState.locationState.isRequestingLocation = false
        isLoading = false
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        isLoading = true
        error = nil
        appState.locationState.isRequestingLocation = true
        appState.locationState.locationError = nil
        
        do {
            let location = try await repository.getCurrentLocation()
            
            // Update app state
            appState.locationState.currentLocation = location
            appState.locationState.authorizationStatus = repository.getAuthorizationStatus()
            appState.locationState.isRequestingLocation = false
            isLoading = false
            
            return location
            
        } catch {
            let locationError = error as? LocationError ?? .locationUnavailable(error)
            self.error = locationError
            appState.locationState.locationError = locationError
            appState.locationState.isRequestingLocation = false
            isLoading = false
            throw error
        }
    }
    
    nonisolated func checkLocationPermission() -> Bool {
        let status = repository.getAuthorizationStatus()
        // Note: We can't update appState here since it's MainActor-isolated
        // This method is for quick permission checks only
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
}