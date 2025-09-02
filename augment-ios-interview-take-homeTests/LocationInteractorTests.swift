//
//  LocationInteractorTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import CoreLocation
@testable import augment_ios_interview_take_home

@MainActor
struct LocationInteractorTests {
    
    let appState: AppState
    let mockRepository: MockLocationRepository
    let locationInteractor: LocationInteractor
    
    init() {
        appState = AppState()
        mockRepository = MockLocationRepository()
        locationInteractor = LocationInteractor(repository: mockRepository, appState: appState)
    }
    
    // MARK: - Permission Request Tests
    
    @Test("Request permission when not determined")
    func requestPermissionWhenNotDetermined() async throws {
        // Setup
        mockRepository.mockAuthorizationStatus = .notDetermined
        
        // Execute
        await locationInteractor.requestLocationPermission()
        
        // Simulate user granting permission
        mockRepository.simulateUserGrantingPermission()
        
        // Verify
        #expect(mockRepository.permissionRequestCount > 0, "Should request permission")
        #expect(locationInteractor.error == nil, "Should not have error")
        #expect(appState.locationState.locationError == nil, "Should not have error in app state")
    }
    
    @Test("Request permission when already authorized")
    func requestPermissionWhenAlreadyAuthorized() async throws {
        // Setup
        mockRepository.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Execute
        await locationInteractor.requestLocationPermission()
        
        // Verify
        #expect(appState.locationState.authorizationStatus == .authorizedWhenInUse, "Should update app state")
    }
    
    @Test("Request permission when denied")
    func requestPermissionWhenDenied() async throws {
        // Setup
        mockRepository.mockAuthorizationStatus = .notDetermined
        
        // Execute
        await locationInteractor.requestLocationPermission()
        
        // Simulate user denying permission
        mockRepository.simulateUserDenyingPermission()
        
        // Check permission status again
        await locationInteractor.checkPermissionStatusAndRetry()
        
        // Verify
        #expect(mockRepository.permissionRequestCount > 0, "Should request permission")
        #expect(appState.locationState.authorizationStatus == .denied, "Should update app state")
    }
    
    // MARK: - Get Current Location Tests
    
    @Test("Get current location successfully")
    func getCurrentLocationSuccessfully() async throws {
        // Setup
        mockRepository.authorizationStatus = .authorizedWhenInUse
        let expectedLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        mockRepository.mockLocation = expectedLocation
        
        // Execute
        let location = try await locationInteractor.getCurrentLocation()
        
        // Verify
        #expect(mockRepository.getCurrentLocationCalled, "Should call repository")
        #expect(location.coordinate.latitude == expectedLocation.coordinate.latitude, "Should return correct location")
        #expect(appState.locationState.currentLocation?.coordinate.latitude == expectedLocation.coordinate.latitude, "Should update app state")
        #expect(locationInteractor.error == nil, "Should not have error")
    }
    
    @Test("Get current location with permission denied")
    func getCurrentLocationWithPermissionDenied() async throws {
        // Setup
        mockRepository.authorizationStatus = .denied
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = LocationError.permissionDenied
        
        // Execute & Verify
        do {
            _ = try await locationInteractor.getCurrentLocation()
            #expect(Bool(false), "Should throw error")
        } catch {
            #expect(error is LocationError, "Should throw LocationError")
            #expect(locationInteractor.error != nil, "Should set error")
            #expect(appState.locationState.locationError != nil, "Should set error in app state")
        }
    }
    
    @Test("Get current location with timeout")
    func getCurrentLocationWithTimeout() async throws {
        // Setup
        mockRepository.authorizationStatus = .authorizedWhenInUse
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = LocationError.timeout
        
        // Execute & Verify
        do {
            _ = try await locationInteractor.getCurrentLocation()
            #expect(Bool(false), "Should throw error")
        } catch {
            #expect(error is LocationError, "Should throw LocationError")
            #expect(locationInteractor.error != nil, "Should set error")
        }
    }
    
    // MARK: - Permission Check Tests
    
    @Test("Check location permission when authorized")
    func checkLocationPermissionWhenAuthorized() {
        // Setup
        mockRepository.authorizationStatus = .authorizedWhenInUse
        
        // Execute
        let hasPermission = locationInteractor.checkLocationPermission()
        
        // Verify
        #expect(hasPermission, "Should have permission")
    }
    
    @Test("Check location permission when denied")
    func checkLocationPermissionWhenDenied() {
        // Setup
        mockRepository.authorizationStatus = .denied
        
        // Execute
        let hasPermission = locationInteractor.checkLocationPermission()
        
        // Verify
        #expect(!hasPermission, "Should not have permission")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Clear error")
    func clearError() {
        // Setup
        locationInteractor.error = LocationError.permissionDenied
        appState.locationState.locationError = LocationError.permissionDenied
        
        // Execute
        locationInteractor.clearError()
        
        // Verify
        #expect(locationInteractor.error == nil, "Should clear error")
        #expect(appState.locationState.locationError == nil, "Should clear error in app state")
    }
    
    @Test("Retry location request after error")
    func retryLocationRequestAfterError() async throws {
        // Setup
        mockRepository.authorizationStatus = .authorizedWhenInUse
        locationInteractor.error = LocationError.timeout
        let expectedLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        mockRepository.mockLocation = expectedLocation
        
        // Execute
        await locationInteractor.retryLocationRequest()
        
        // Verify
        #expect(mockRepository.getCurrentLocationCalled, "Should retry location request")
        #expect(locationInteractor.error == nil, "Should clear error on success")
    }
    
    @Test("Check permission status and retry")
    func checkPermissionStatusAndRetry() async {
        // Setup
        mockRepository.authorizationStatus = .authorizedWhenInUse
        locationInteractor.error = LocationError.permissionDenied
        appState.locationState.locationError = LocationError.permissionDenied
        appState.weatherState.error = .networkFailure(URLError(.notConnectedToInternet))
        
        // Execute
        await locationInteractor.checkPermissionStatusAndRetry()
        
        // Verify
        #expect(appState.locationState.authorizationStatus == .authorizedWhenInUse, "Should update status")
        #expect(locationInteractor.error == nil, "Should clear location error")
        #expect(appState.locationState.locationError == nil, "Should clear location error in app state")
        #expect(appState.weatherState.error == nil, "Should clear weather error")
    }
    
    // MARK: - Loading State Tests
    
    @Test("Loading state during permission request")
    func loadingStateDuringPermissionRequest() async {
        // Setup
        mockRepository.authorizationStatus = .notDetermined
        mockRepository.requestPermissionDelay = 0.1
        
        // Execute
        let task = Task {
            await locationInteractor.requestLocationPermission()
        }
        
        // Check loading state
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        #expect(locationInteractor.isLoading, "Should be loading")
        #expect(appState.locationState.isRequestingLocation, "Should be requesting in app state")
        
        await task.value
        
        // Verify final state
        #expect(!locationInteractor.isLoading, "Should not be loading after completion")
    }
    
    @Test("Loading state during location fetch")
    func loadingStateDuringLocationFetch() async throws {
        // Setup
        mockRepository.authorizationStatus = .authorizedWhenInUse
        mockRepository.getCurrentLocationDelay = 0.1
        let expectedLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        mockRepository.mockLocation = expectedLocation
        
        // Execute
        let task = Task {
            try await locationInteractor.getCurrentLocation()
        }
        
        // Check loading state
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        #expect(locationInteractor.isLoading, "Should be loading")
        
        _ = try await task.value
        
        // Verify final state
        #expect(!locationInteractor.isLoading, "Should not be loading after completion")
    }
}

