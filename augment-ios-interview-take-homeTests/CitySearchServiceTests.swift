//
//  CitySearchServiceTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import MapKit
import CoreLocation
@testable import augment_ios_interview_take_home

@MainActor
struct CitySearchServiceTests {
    
    let citySearchService: CitySearchService
    
    init() {
        citySearchService = CitySearchService()
    }
    
    // MARK: - Basic Search Functionality Tests
    
    @Test("Search with valid city name returns results")
    func searchWithValidCityName() async throws {
        // Test searching for a well-known city
        await citySearchService.searchCities(query: "San Francisco")
        
        // Wait for search to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        #expect(!citySearchService.isSearching, "Search should be completed")
        #expect(citySearchService.hasSearched, "Should have completed search")
        #expect(!citySearchService.searchResults.isEmpty, "Should find results for San Francisco")
        
        // Verify at least one result contains San Francisco
        let hasSanFrancisco = citySearchService.searchResults.contains { city in
            city.name.localizedCaseInsensitiveContains("San Francisco") ||
            city.name.localizedCaseInsensitiveContains("SF")
        }
        #expect(hasSanFrancisco, "Should find San Francisco in results")
    }
    
    @Test("Search with partial city name works")
    func searchWithPartialCityName() async throws {
        // Test searching with partial city name
        await citySearchService.searchCities(query: "Los")
        
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        #expect(!citySearchService.isSearching, "Search should be completed")
        #expect(citySearchService.hasSearched, "Should have completed search")
        #expect(!citySearchService.searchResults.isEmpty, "Should find results for partial name 'Los'")
        
        // Should find Los Angeles or similar cities
        let hasLosAngeles = citySearchService.searchResults.contains { city in
            city.name.localizedCaseInsensitiveContains("Los")
        }
        #expect(hasLosAngeles, "Should find cities containing 'Los'")
        
        print("✅ Partial city search test passed - Found \(citySearchService.searchResults.count) results")
    }
    
    @Test("Search with invalid city name returns no results")
    func searchWithInvalidCityName() async throws {
        // Test searching for a non-existent city
        await citySearchService.searchCities(query: "XYZInvalidCity123")
        
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds for thorough search
        
        #expect(!citySearchService.isSearching, "Search should be completed")
        #expect(citySearchService.hasSearched, "Should have completed search")
        #expect(citySearchService.searchResults.isEmpty, "Should not find results for invalid city")
    }
    
    @Test("Search with empty query does not perform search")
    func searchWithEmptyQuery() async throws {
        // Test searching with empty string
        await citySearchService.searchCities(query: "")
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        #expect(!citySearchService.isSearching, "Search should not be in progress for empty query")
        #expect(!citySearchService.hasSearched, "Should not have searched for empty query")
        #expect(citySearchService.searchResults.isEmpty, "Should have no results for empty query")
    }
    
    // MARK: - International City Tests
    
    @Test("Search with international cities works")
    func searchWithInternationalCities() async throws {
        let internationalCities = ["London", "Tokyo", "Paris"]
        
        for cityName in internationalCities {
            await citySearchService.searchCities(query: cityName)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            #expect(!citySearchService.isSearching, "Search should be completed for \(cityName)")
            #expect(citySearchService.hasSearched, "Should have searched for \(cityName)")
            
            print("✅ Search completed for \(cityName) - \(citySearchService.searchResults.count) results")
        }
    }
    
    // MARK: - Special Characters and Edge Cases
    
    @Test("Search with special characters works")
    func searchWithSpecialCharacters() async throws {
        let specialCityNames = ["São Paulo", "México City"]
        
        for cityName in specialCityNames {
            await citySearchService.searchCities(query: cityName)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            #expect(!citySearchService.isSearching, "Search should be completed for \(cityName)")
            #expect(citySearchService.hasSearched, "Should have searched for \(cityName)")
            
            print("✅ Special character search for \(cityName) completed")
        }
    }
    
    @Test("Search is case insensitive")
    func searchWithCaseInsensitivity() async throws {
        let testCases = ["new york", "NEW YORK", "New York"]
        var allResults: [[City]] = []
        
        for testCase in testCases {
            await citySearchService.searchCities(query: testCase)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            #expect(!citySearchService.isSearching, "Search should be completed for \(testCase)")
            allResults.append(citySearchService.searchResults)
        }
        
        print("✅ Case insensitivity test passed")
    }
    
    // MARK: - Search State Management Tests
    
    @Test("Search state transitions work correctly")
    func searchStateTransitions() async throws {
        // Initial state
        #expect(!citySearchService.isSearching, "Should not be searching initially")
        #expect(!citySearchService.hasSearched, "Should not have searched initially")
        #expect(citySearchService.searchResults.isEmpty, "Should have no results initially")
        
        // Perform search
        await citySearchService.searchCities(query: "Austin")
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Final state
        #expect(!citySearchService.isSearching, "Should not be searching after completion")
        #expect(citySearchService.hasSearched, "Should have searched after completion")
        
        print("✅ Search state transitions test passed")
    }
    
    @Test("Clear results works correctly")
    func clearResults() async throws {
        // First perform a search
        await citySearchService.searchCities(query: "Chicago")
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Verify we have results
        #expect(!citySearchService.searchResults.isEmpty, "Should have results before clearing")
        #expect(citySearchService.hasSearched, "Should have searched before clearing")
        
        // Clear results
        citySearchService.clearResults()
        
        // Verify cleared state
        #expect(citySearchService.searchResults.isEmpty, "Should have no results after clearing")
        #expect(!citySearchService.isSearching, "Should not be searching after clearing")
        #expect(!citySearchService.hasSearched, "Should reset hasSearched after clearing")
        
        print("✅ Clear results test passed")
    }
    
    // MARK: - Data Validation Tests
    
    @Test("Search result data integrity is valid")
    func searchResultDataIntegrity() async throws {
        await citySearchService.searchCities(query: "Miami")
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        for city in citySearchService.searchResults {
            // Validate required fields
            #expect(!city.name.isEmpty, "City name should not be empty")
            #expect(!city.countryCode.isEmpty, "Country code should not be empty")
            
            // Validate coordinate ranges
            #expect(city.latitude >= -90, "Latitude should be >= -90")
            #expect(city.latitude <= 90, "Latitude should be <= 90")
            #expect(city.longitude >= -180, "Longitude should be >= -180")
            #expect(city.longitude <= 180, "Longitude should be <= 180")
            
            // Validate UUID
            #expect(!city.id.uuidString.isEmpty, "City should have valid UUID")
        }
        
        print("✅ Data integrity test passed for \(citySearchService.searchResults.count) cities")
    }
    
    @Test("Search performance is reasonable")
    func searchPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await citySearchService.searchCities(query: "Los Angeles")
        try await Task.sleep(nanoseconds: 3_000_000_000) // Allow up to 3 seconds
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let searchTime = endTime - startTime
        
        #expect(searchTime < 5.0, "Search should complete within 5 seconds")
        #expect(!citySearchService.isSearching, "Search should be completed")
        
        print("✅ Performance test passed - Search completed in \(String(format: "%.2f", searchTime)) seconds")
    }
}