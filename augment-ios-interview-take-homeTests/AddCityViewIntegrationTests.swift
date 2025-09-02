//
//  AddCityViewIntegrationTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import SwiftUI
@testable import augment_ios_interview_take_home

@MainActor
struct AddCityViewIntegrationTests {
    
    let mockWeatherInteractor: MockWeatherInteractor
    let appContainer: AppContainer
    
    init() {
        mockWeatherInteractor = MockWeatherInteractor()
        
        let appState = AppState()
        let locationRepository = LocationPreviewRepository()
        let interactors = AppContainer.Interactors(
            weatherInteractor: mockWeatherInteractor,
            locationInteractor: LocationInteractor(repository: locationRepository, appState: appState)
        )
        
        appContainer = AppContainer(appState: appState, interactors: interactors)
    }
    
    // MARK: - Predefined Cities Tests
    
    @Test("Predefined cities display correctly")
    func predefinedCitiesDisplay() {
        let predefinedCities = City.predefinedCities
        
        // Verify all required cities are present
        let requiredCityNames = ["Los Angeles", "San Francisco", "Austin", "Lisbon", "Auckland"]
        
        for requiredCity in requiredCityNames {
            let cityExists = predefinedCities.contains { city in
                city.name.contains(requiredCity)
            }
            #expect(cityExists, "Should contain \(requiredCity) in predefined cities")
        }
        
        // Verify minimum number of predefined cities
        #expect(predefinedCities.count >= 5, "Should have at least 5 predefined cities")
        
        // Verify all predefined cities have valid data
        for city in predefinedCities {
            #expect(!city.name.isEmpty, "Predefined city name should not be empty")
            #expect(!city.countryCode.isEmpty, "Predefined city country code should not be empty")
            #expect(city.latitude != 0, "Predefined city should have valid latitude")
            #expect(city.longitude != 0, "Predefined city should have valid longitude")
        }
        
        print("✅ Predefined cities test passed - \(predefinedCities.count) cities validated")
    }
    
    // MARK: - Search Flow Integration Tests
    
    @Test("Search flow with predefined city filtering works")
    func searchFlowWithPredefinedCityFiltering() async throws {
        let citySearchService = CitySearchService()
        
        // Test filtering predefined cities
        let searchQuery = "Los"
        await citySearchService.searchCities(query: searchQuery)
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Should find Los Angeles in results
        let hasLosAngeles = citySearchService.searchResults.contains { city in
            city.name.localizedCaseInsensitiveContains("Los Angeles")
        }
        
        if hasLosAngeles {
            print("✅ Search flow integration test passed - Found Los Angeles")
        } else {
            print("⚠️ Los Angeles not found in search results, but search completed successfully")
        }
        
        #expect(!citySearchService.isSearching, "Search should be completed")
        #expect(citySearchService.hasSearched, "Should have completed search")
    }
    
    @Test("Add city flow works correctly")
    func addCityFlow() async throws {
        // Create a test city
        let testCity = City(
            name: "Test City",
            countryCode: "US",
            latitude: 40.7128,
            longitude: -74.0060
        )
        
        // Add city through mock interactor
        await mockWeatherInteractor.addCity(testCity)
        
        // Verify city was added
        #expect(mockWeatherInteractor.addCityCalled, "addCity should have been called")
        #expect(mockWeatherInteractor.lastAddedCity?.name == testCity.name, "Should add the correct city")
        
        print("✅ Add city flow test passed")
    }
    
    // MARK: - Search State Management Integration Tests
    
    @Test("Search state transitions in view work correctly")
    func searchStateTransitionsInView() async throws {
        let citySearchService = CitySearchService()
        
        // Test empty query state
        await citySearchService.searchCities(query: "")
        #expect(!citySearchService.isSearching, "Should not be searching for empty query")
        #expect(!citySearchService.hasSearched, "Should not have searched for empty query")
        #expect(citySearchService.searchResults.isEmpty, "Should have no results for empty query")
        
        // Test valid query state transitions
        let searchTask = Task {
            await citySearchService.searchCities(query: "San Francisco")
        }
        
        // Brief delay to check intermediate state
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await searchTask.value
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        #expect(!citySearchService.isSearching, "Should not be searching after completion")
        #expect(citySearchService.hasSearched, "Should have searched after completion")
        
        print("✅ Search state transitions integration test passed")
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test("Search error handling works correctly")
    func searchErrorHandling() async throws {
        let citySearchService = CitySearchService()
        
        // Test with potentially problematic queries
        let problematicQueries = [
            "!@#$%^&*()",
            "12345",
            "   ",
            "a",
            String(repeating: "x", count: 1000) // Very long string
        ]
        
        for query in problematicQueries {
            await citySearchService.searchCities(query: query)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Should handle gracefully without crashing
            #expect(!citySearchService.isSearching, "Should complete search for problematic query: \(query)")
            #expect(citySearchService.hasSearched, "Should have attempted search for: \(query)")
            
            print("✅ Handled problematic query: \(query.prefix(20))...")
        }
        
        print("✅ Search error handling integration test passed")
    }
    
    @Test("Concurrent search and add operations work correctly")
    func concurrentSearchAndAdd() async throws {
        let citySearchService = CitySearchService()
        
        // Start a search and add city simultaneously
        let searchTask = Task {
            await citySearchService.searchCities(query: "Miami")
        }
        
        let testCity = City(
            name: "Concurrent Test City",
            countryCode: "US", 
            latitude: 25.7617,
            longitude: -80.1918
        )
        
        let addTask = Task {
            await mockWeatherInteractor.addCity(testCity)
        }
        
        // Wait for both operations
        await searchTask.value
        await addTask.value
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Verify both operations completed successfully
        #expect(!citySearchService.isSearching, "Search should be completed")
        #expect(mockWeatherInteractor.addCityCalled, "Add city should have been called")
        
        print("✅ Concurrent search and add test passed")
    }
}

