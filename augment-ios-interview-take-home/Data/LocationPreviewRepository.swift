//
//  LocationPreviewRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

final class LocationPreviewRepository: LocationRepositoryProtocol, @unchecked Sendable {
    private var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    
    func requestLocationPermission() async {
        // Simulate permission request
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        authorizationStatus = .authorizedWhenInUse
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        // Simulate location fetch delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return San Francisco coordinates as sample
        return CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return authorizationStatus
    }
    
    // Helper method for testing different scenarios
    func setAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
    
    // MARK: - Location Monitoring (Preview Implementation)
    
    nonisolated func startLocationMonitoring(onLocationUpdate: @escaping (CLLocation) -> Void) {
        // Preview implementation - no-op for previews
    }
    
    nonisolated func stopLocationMonitoring() {
        // Preview implementation - no-op for previews
    }
}