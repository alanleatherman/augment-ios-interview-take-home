//
//  MockLocationRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import Foundation
import CoreLocation

class MockLocationRepository: LocationRepositoryProtocol, @unchecked Sendable {
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var mockLocation: CLLocation?
    var shouldThrowError = false
    var errorToThrow: LocationError = .permissionDenied
    var permissionRequestCount = 0
    
    var authorizationStatus: CLAuthorizationStatus {
        get { mockAuthorizationStatus }
        set { mockAuthorizationStatus = newValue }
    }
    
    var getCurrentLocationCalled = false
    var requestPermissionDelay: TimeInterval = 0
    var getCurrentLocationDelay: TimeInterval = 0
    
    func requestLocationPermission() async {
        // Simulate permission request
        permissionRequestCount += 1
        
        // Simulate system dialog delay with configurable delay
        if requestPermissionDelay > 0 {
            try? await Task.sleep(for: .seconds(requestPermissionDelay))
        } else {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        getCurrentLocationCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard mockAuthorizationStatus == .authorizedWhenInUse || mockAuthorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        guard let location = mockLocation else {
            throw LocationError.locationUnavailable(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock location set"]))
        }
        
        // Simulate location fetch delay with configurable delay
        if getCurrentLocationDelay > 0 {
            try await Task.sleep(for: .seconds(getCurrentLocationDelay))
        } else {
            try await Task.sleep(for: .milliseconds(100))
        }
        
        return location
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return mockAuthorizationStatus
    }
    
    // Helper methods for testing
    func reset() {
        mockAuthorizationStatus = .notDetermined
        mockLocation = nil
        shouldThrowError = false
        errorToThrow = .permissionDenied
        permissionRequestCount = 0
        getCurrentLocationCalled = false
        requestPermissionDelay = 0
        getCurrentLocationDelay = 0
    }
    
    func simulateUserGrantingPermission() {
        mockAuthorizationStatus = .authorizedWhenInUse
    }
    
    func simulateUserDenyingPermission() {
        mockAuthorizationStatus = .denied
    }
    
    // MARK: - Location Monitoring (Mock Implementation)
    
    nonisolated func startLocationMonitoring(onLocationUpdate: @escaping (CLLocation) -> Void) {
        // Mock implementation - no-op for testing
    }
    
    nonisolated func stopLocationMonitoring() {
        // Mock implementation - no-op for testing
    }
}
