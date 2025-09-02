//
//  SearchFlowNetworkTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import MapKit
import CoreLocation
@testable import augment_ios_interview_take_home

@MainActor
struct SearchFlowNetworkTests {
    
    let citySearchService: CitySearchService
    
    init() {
        citySearchService = CitySearchService()
    }
    
    @Test("Search with various city names works")
    func searchWithVariousCityNames() async throws {
        let testCities = ["New York", "Los Angeles", "London", "Tokyo", "São Paulo"]
        var successCount = 0
        
        for cityName in testCities {
            await citySearchService.searchCities(query: cityName)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            let searchCompleted = citySearchService.hasSearched && !citySearchService.isSearching
            #expect(searchCompleted, "Search should complete for: \(cityName)")
            
            if !citySearchService.searchResults.isEmpty {
                successCount += 1
            }
            
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        let successRate = Double(successCount) / Double(testCities.count)
        #expect(successRate > 0.6, "Should find results for most major cities")
        
        print("✅ Search success rate: \(successCount)/\(testCities.count)")
    }
    
    @Test("Search handles error conditions gracefully")
    func searchErrorRecovery() async throws {
        let errorProneQueries = ["", "!@#$%", "12345", String(repeating: "x", count: 100)]
        
        for query in errorProneQueries {
            await citySearchService.searchCities(query: query)
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Should handle gracefully without crashing
            #expect(!citySearchService.isSearching, "Should handle error-prone query: \(query.prefix(10))")
            
            citySearchService.clearResults()
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        
        print("✅ Error handling test passed")
    }
    
    @Test("Search performance is reasonable")
    func searchPerformance() async throws {
        let testCities = ["Boston", "Chicago", "Miami"]
        var totalTime: Double = 0
        
        for cityName in testCities {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            await citySearchService.searchCities(query: cityName)
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let searchTime = endTime - startTime
            totalTime += searchTime
            
            #expect(searchTime < 5.0, "\(cityName) search should complete within 5 seconds")
        }
        
        let averageTime = totalTime / Double(testCities.count)
        #expect(averageTime < 4.0, "Average search time should be reasonable")
        
        print("✅ Performance test passed - Average: \(String(format: "%.2f", averageTime))s")
    }
}
