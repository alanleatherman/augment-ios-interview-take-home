//
//  WeatherRepositoryTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
@testable import augment_ios_interview_take_home

@MainActor
struct WeatherRepositoryTests {
    
    // MARK: - Preview Repository Tests
    
    @Test("Preview repository returns sample data")
    func previewRepositoryReturnsData() async throws {
        let repository = WeatherPreviewRepository()
        let testCity = City(name: "Test City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        
        // Test current weather
        let weather = try await repository.getCurrentWeather(for: testCity)
        #expect(weather.temperature > -100 && weather.temperature < 150, "Should return reasonable temperature")
        #expect(!weather.description.isEmpty, "Should have weather description")
        
        // Test forecasts
        let hourlyForecast = try await repository.getHourlyForecast(for: testCity)
        let dailyForecast = try await repository.getDailyForecast(for: testCity)
        
        #expect(!hourlyForecast.isEmpty, "Should return hourly forecast")
        #expect(!dailyForecast.isEmpty, "Should return daily forecast")
    }
    
    @Test("Preview repository caching works")
    func previewRepositoryCaching() async throws {
        let repository = WeatherPreviewRepository()
        let testCity = City(name: "Test City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        
        // Get weather and cache it
        let weather = try await repository.getCurrentWeather(for: testCity)
        repository.cacheWeather(weather)
        
        // Retrieve from cache
        let cachedWeather = repository.getCachedWeather(for: testCity.id)
        #expect(cachedWeather?.id == weather.id, "Should retrieve same weather from cache")
    }
    
    // MARK: - Web Repository Tests
    
    @Test("Web repository basic functionality")
    func webRepositoryBasicFunctionality() async throws {
        let appSettings = AppSettings()
        let repository = WeatherWebRepository(appSettings: appSettings)
        
        // Test with known coordinates (San Francisco)
        let weather = try await repository.getCurrentWeather(latitude: 37.7749, longitude: -122.4194)
        
        #expect(weather.temperature > -50 && weather.temperature < 150, "Should return reasonable temperature")
        #expect(!weather.description.isEmpty, "Should have description")
        #expect(!weather.iconCode.isEmpty, "Should have icon code")
        #expect(weather.humidity >= 0 && weather.humidity <= 100, "Should have valid humidity")
    }
    
    @Test("Web repository error handling")
    func webRepositoryErrorHandling() async throws {
        let appSettings = AppSettings()
        let repository = WeatherWebRepository(appSettings: appSettings)
        
        // Test with invalid coordinates
        await #expect(throws: WeatherError.self) {
            _ = try await repository.getCurrentWeather(latitude: 999.0, longitude: 999.0)
        }
    }
}
