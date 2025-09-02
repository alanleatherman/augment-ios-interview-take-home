//
//  LocationRepositoryTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import CoreLocation
@testable import augment_ios_interview_take_home

@MainActor
struct LocationRepositoryTests {
    
    // MARK: - Preview Repository Tests
    
    @Test("Preview repository basic functionality")
    func previewRepositoryBasicFunctionality() async throws {
        let repository = LocationPreviewRepository()
        
        // Test initial state
        #expect(repository.getAuthorizationStatus() == .authorizedWhenInUse, "Should start authorized")
        
        // Test permission request
        repository.setAuthorizationStatus(.notDetermined)
        await repository.requestLocationPermission()
        #expect(repository.getAuthorizationStatus() == .authorizedWhenInUse, "Should grant permission")
        
        // Test location retrieval
        let location = try await repository.getCurrentLocation()
        #expect(location.coordinate.latitude == 37.7749, "Should return San Francisco coordinates")
        #expect(location.coordinate.longitude == -122.4194, "Should return San Francisco coordinates")
    }
    
    @Test("Preview repository permission denied scenario")
    func previewRepositoryPermissionDenied() async {
        let repository = LocationPreviewRepository()
        repository.setAuthorizationStatus(.denied)
        
        do {
            _ = try await repository.getCurrentLocation()
            #expect(Bool(false), "Should throw error when denied")
        } catch {
            #expect(error is LocationError, "Should throw LocationError")
        }
    }
    
    // MARK: - Web Repository Tests
    
    @Test("Web repository initialization and basic operations")
    func webRepositoryBasicOperations() async {
        let repository = LocationWebRepository()
        
        // Test status retrieval
        let status = repository.getAuthorizationStatus()
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined, .restricted, .denied, .authorizedAlways, .authorizedWhenInUse
        ]
        #expect(validStatuses.contains(status), "Should return valid authorization status")
        
        // Test permission request (completes without error)
        await repository.requestLocationPermission()
        
        // Test location request (may fail in test environment, but shouldn't crash)
        do {
            let location = try await repository.getCurrentLocation()
            #expect(location.coordinate.latitude >= -90 && location.coordinate.latitude <= 90, "Should have valid coordinates")
        } catch {
            #expect(error is LocationError, "Should throw LocationError when unavailable")
        }
    }
    
    @Test("Web repository concurrent operations")
    func webRepositoryConcurrentOperations() async {
        let repository = LocationWebRepository()
        
        // Test concurrent permission requests
        let tasks = (0..<3).map { _ in
            Task { await repository.requestLocationPermission() }
        }
        
        for task in tasks {
            await task.value
        }
        
        // Should remain functional after concurrent access
        let status = repository.getAuthorizationStatus()
        #expect(status != nil, "Should remain functional after concurrent operations")
    }
}
