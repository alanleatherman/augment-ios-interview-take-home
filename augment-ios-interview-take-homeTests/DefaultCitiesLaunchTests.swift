//
//  DefaultCitiesLaunchTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import SwiftData
@testable import augment_ios_interview_take_home

@MainActor
struct DefaultCitiesLaunchTests {
    
    let weatherInteractor: WeatherInteractor
    let appState: AppState
    
    init() {
        appState = AppState()
        let weatherRepository = WeatherPreviewRepository()
        weatherInteractor = WeatherInteractor(repository: weatherRepository, appState: appState)
    }
    
    @Test("Default cities appear on first launch")
    func defaultCitiesAppearOnFirstLaunch() async throws {
        // Verify app state starts empty
        #expect(appState.weatherState.cities.isEmpty, "App state should start empty")
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify default cities are present
        #expect(!appState.weatherState.cities.isEmpty, "Cities should be populated")
        #expect(appState.weatherState.cities.count >= 6, "Should have at least 6 default cities")
        
        // Verify required cities exist
        let requiredCities = ["Los Angeles", "San Francisco", "Austin", "Lisbon", "Auckland", "Rio de Janeiro"]
        for cityName in requiredCities {
            let cityExists = appState.weatherState.cities.contains { $0.name == cityName }
            #expect(cityExists, "Should contain \(cityName)")
        }
        
        print("✅ Default cities loaded: \(appState.weatherState.cities.count)")
    }
    
    @Test("Default cities have valid data")
    func defaultCitiesHaveValidData() async throws {
        await weatherInteractor.loadInitialData()
        
        // Verify all cities have valid data
        for city in appState.weatherState.cities {
            #expect(!city.name.isEmpty, "City name should not be empty")
            #expect(!city.countryCode.isEmpty, "Country code should not be empty")
            #expect(city.latitude > -90 && city.latitude < 90, "Latitude should be valid")
            #expect(city.longitude > -180 && city.longitude < 180, "Longitude should be valid")
        }
        
        print("✅ Data validation passed for \(appState.weatherState.cities.count) cities")
    }
    
    @Test("App state consistency after launch")
    func appStateConsistencyAfterLaunch() async throws {
        await weatherInteractor.loadInitialData()
        
        #expect(!appState.weatherState.isLoading, "Loading should be complete")
        #expect(appState.weatherState.lastRefresh != nil, "Last refresh should be set")
        #expect(appState.weatherState.hasData, "Should have data")
        #expect(!appState.weatherState.isEmpty, "Should not be empty")
        
        print("✅ App state consistency verified")
    }
}
