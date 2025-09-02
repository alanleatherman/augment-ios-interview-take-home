//
//  LocationPermissionTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import CoreLocation
@testable import augment_ios_interview_take_home

@MainActor
struct LocationPermissionTests {
    
    let appState: AppState
    let mockLocationRepository: MockLocationRepository
    let locationInteractor: LocationInteractor
    let appContainer: AppContainer
    
    init() {
        appState = AppState()
        mockLocationRepository = MockLocationRepository()
        locationInteractor = LocationInteractor(repository: mockLocationRepository, appState: appState)
        
        let weatherInteractor = WeatherInteractor(
            repository: WeatherPreviewRepository(),
            appState: appState
        )
        
        let interactors = AppContainer.Interactors(
            weatherInteractor: weatherInteractor,
            locationInteractor: locationInteractor
        )
        
        appContainer = AppContainer(appState: appState, interactors: interactors)
    }
    
    @Test("Location permission request granted updates state correctly")
    func locationPermissionRequestGranted() async throws {
        // Initially, permission should be not determined
        #expect(appState.locationState.authorizationStatus == .notDetermined)
        #expect(!appState.locationState.hasLocationPermission)
        
        // Mock granting permission
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Request permission
        await locationInteractor.requestLocationPermission()
        
        // Verify permission was granted
        #expect(appState.locationState.authorizationStatus == .authorizedWhenInUse)
        #expect(appState.locationState.hasLocationPermission)
        #expect(appState.locationState.locationError == nil)
    }
    
    @Test("Location permission denied sets error state")
    func locationPermissionDenied() async throws {
        // Mock denying permission
        mockLocationRepository.mockAuthorizationStatus = .denied
        
        // Request permission
        await locationInteractor.requestLocationPermission()
        
        // Verify permission was denied and error was set
        #expect(appState.locationState.authorizationStatus == .denied)
        #expect(!appState.locationState.hasLocationPermission)
        #expect(appState.locationState.locationError != nil)
        #expect(appState.locationState.locationError == .permissionDenied)
    }
    
    @Test("Add current location city with permission succeeds")
    func addCurrentLocationCityWithPermission() async throws {
        // Mock location permission granted
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        mockLocationRepository.mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Initially no cities
        #expect(appState.weatherState.cities.isEmpty)
        
        // Add current location city
        await appContainer.addCurrentLocationCity()
        
        // Verify current location city was added
        #expect(appState.weatherState.cities.count == 1)
        let addedCity = appState.weatherState.cities.first!
        #expect(addedCity.isCurrentLocation)
        #expect(addedCity.name == "San Francisco")
        #expect(abs(addedCity.latitude - 37.7749) < 0.001)
        #expect(abs(addedCity.longitude - (-122.4194)) < 0.001)
    }
    
    @Test("Add current location city without permission fails gracefully")
    func addCurrentLocationCityWithoutPermission() async throws {
        // Mock location permission denied
        mockLocationRepository.mockAuthorizationStatus = .denied
        
        // Initially no cities
        #expect(appState.weatherState.cities.isEmpty)
        
        // Try to add current location city
        await appContainer.addCurrentLocationCity()
        
        // Verify no city was added and error was set
        #expect(appState.weatherState.cities.isEmpty)
        #expect(appState.weatherState.error != nil)
        #expect(appState.weatherState.error == .locationPermissionDenied)
    }
    
    @Test("Add current location city when one already exists prevents duplicates")
    func addCurrentLocationCityAlreadyExists() async throws {
        // Add a current location city first
        let existingCity = City(
            name: "Current Location",
            countryCode: "",
            latitude: 40.7128,
            longitude: -74.0060,
            isCurrentLocation: true
        )
        appState.weatherState.cities.append(existingCity)
        
        // Mock location permission granted
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        mockLocationRepository.mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Try to add current location city again
        await appContainer.addCurrentLocationCity()
        
        // Verify only one current location city exists (no duplicate)
        let currentLocationCities = appState.weatherState.cities.filter { $0.isCurrentLocation }
        #expect(currentLocationCities.count == 1)
        #expect(appState.weatherState.cities.count == 1)
    }
    
    @Test("Location permission already granted remains stable")
    func locationPermissionAlreadyGranted() async throws {
        // Set permission as already granted
        appState.locationState.authorizationStatus = .authorizedWhenInUse
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Request permission again
        await locationInteractor.requestLocationPermission()
        
        // Should remain granted with no error
        #expect(appState.locationState.authorizationStatus == .authorizedWhenInUse)
        #expect(appState.locationState.hasLocationPermission)
        #expect(appState.locationState.locationError == nil)
    }
    
    @Test("Location fetching timeout throws correct error")
    func locationFetchingTimeout() async throws {
        // Mock permission granted but location fetch times out
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        mockLocationRepository.shouldThrowError = true
        mockLocationRepository.errorToThrow = .timeout
        
        // Try to get current location
        await #expect(throws: LocationError.self) {
            _ = try await locationInteractor.getCurrentLocation()
        }
    }
    
    @Test("Location state initialization has correct default values")
    func locationStateInitialization() {
        // Test that location state is properly initialized
        #expect(appState.locationState.authorizationStatus == .notDetermined)
        #expect(!appState.locationState.hasLocationPermission)
        #expect(appState.locationState.canRequestLocation) // Should be true when .notDetermined
        #expect(appState.locationState.currentLocation == nil)
        #expect(appState.locationState.locationError == nil)
        #expect(!appState.locationState.isRequestingLocation)
    }
    
    @Test("Location permission denied is handled gracefully")
    func locationPermissionDeniedGracefulHandling() async throws {
        // Mock permission denied
        mockLocationRepository.mockAuthorizationStatus = .denied
        
        // Try to add current location city
        await appContainer.addCurrentLocationCity()
        
        // Verify graceful handling
        #expect(appState.weatherState.cities.isEmpty)
        #expect(appState.weatherState.error != nil)
        #expect(appState.weatherState.error == .locationPermissionDenied)
        #expect(!appState.locationState.isRequestingLocation) // Should be cleared
        #expect(appState.locationState.authorizationStatus == .denied)
    }
    
    @Test("Location permission retry after settings change works")
    func locationPermissionRetryAfterSettings() async throws {
        // Initially denied
        mockLocationRepository.mockAuthorizationStatus = .denied
        appState.locationState.authorizationStatus = .denied
        appState.locationState.locationError = .permissionDenied
        appState.weatherState.error = .locationPermissionDenied
        
        // Simulate user enabling permission in Settings
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        mockLocationRepository.mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Check permission status and retry
        await locationInteractor.checkPermissionStatusAndRetry()
        
        // Verify errors are cleared
        #expect(appState.locationState.authorizationStatus == .authorizedWhenInUse)
        #expect(appState.locationState.locationError == nil)
        #expect(appState.weatherState.error == nil)
        #expect(appState.locationState.hasLocationPermission)
    }
    
    @Test("App did become active handling adds current location when permission granted")
    func appDidBecomeActiveHandling() async throws {
        // Initially no permission and no cities
        mockLocationRepository.mockAuthorizationStatus = .denied
        appState.locationState.authorizationStatus = .denied
        #expect(appState.weatherState.cities.isEmpty)
        
        // Simulate user enabling permission in Settings
        mockLocationRepository.mockAuthorizationStatus = .authorizedWhenInUse
        mockLocationRepository.mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Handle app becoming active
        await appContainer.handleAppDidBecomeActive()
        
        // Verify current location city was added
        #expect(appState.weatherState.cities.count == 1)
        let addedCity = appState.weatherState.cities.first!
        #expect(addedCity.isCurrentLocation)
        #expect(appState.locationState.authorizationStatus == .authorizedWhenInUse)
    }
    
    @Test("Location permission restricted is handled like denied")
    func locationPermissionRestrictedHandling() async throws {
        // Mock permission restricted (parental controls, etc.)
        mockLocationRepository.mockAuthorizationStatus = .restricted
        
        // Request permission
        await locationInteractor.requestLocationPermission()
        
        // Verify restricted is handled like denied
        #expect(appState.locationState.authorizationStatus == .restricted)
        #expect(!appState.locationState.hasLocationPermission)
        #expect(appState.locationState.locationError != nil)
        #expect(appState.locationState.locationError == .permissionDenied)
    }
    
    @Test("Location permission already denied does not retry")
    func locationPermissionAlreadyDeniedNoRetry() async throws {
        // Set permission as already denied
        mockLocationRepository.mockAuthorizationStatus = .denied
        appState.locationState.authorizationStatus = .denied
        
        // Try to add current location city
        await appContainer.addCurrentLocationCity()
        
        // Verify it doesn't try to request permission again
        #expect(appState.locationState.authorizationStatus == .denied)
        #expect(appState.weatherState.error != nil)
        #expect(appState.weatherState.error == .locationPermissionDenied)
        #expect(appState.weatherState.cities.isEmpty)
    }
}
