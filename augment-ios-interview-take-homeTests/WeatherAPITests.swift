//
//  WeatherAPITests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
@testable import augment_ios_interview_take_home

struct WeatherAPITests {
    
    let repository: WeatherWebRepository
    
    init() {
        let appSettings = AppSettings()
        repository = WeatherWebRepository(appSettings: appSettings)
    }
    
    @Test("Current weather API returns valid data")
    func currentWeatherAPI() async throws {
        // Test with San Francisco coordinates
        let latitude = 37.7749
        let longitude = -122.4194
        
        let weather = try await repository.getCurrentWeather(latitude: latitude, longitude: longitude)
        
        // Verify we got valid weather data
        #expect(weather.temperature > -50, "Temperature should be reasonable")
        #expect(weather.temperature < 150, "Temperature should be reasonable")
        #expect(!weather.description.isEmpty, "Description should not be empty")
        #expect(!weather.iconCode.isEmpty, "Icon code should not be empty")
        #expect(weather.humidity >= 0, "Humidity should be non-negative")
        #expect(weather.humidity <= 100, "Humidity should not exceed 100%")
        #expect(weather.pressure > 800, "Pressure should be reasonable")
        #expect(weather.pressure < 1200, "Pressure should be reasonable")
    }
    
    @Test("Forecast API returns valid hourly and daily data")
    func forecastAPI() async throws {
        // Create a test city
        let testCity = City(
            name: "San Francisco",
            countryCode: "US",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        let hourlyForecast = try await repository.getHourlyForecast(for: testCity)
        let dailyForecast = try await repository.getDailyForecast(for: testCity)
        
        // Verify hourly forecast (5-day forecast API provides data every 3 hours for 5 days = 40 data points)
        #expect(!hourlyForecast.isEmpty, "Hourly forecast should not be empty")
        #expect(hourlyForecast.count <= 40, "Should return at most 40 forecast data points")
        #expect(hourlyForecast.count >= 30, "Should return at least 30 forecast data points")
        
        for hourly in hourlyForecast {
            #expect(hourly.temperature > -50, "Hourly temperature should be reasonable")
            #expect(hourly.temperature < 150, "Hourly temperature should be reasonable")
            #expect(!hourly.iconCode.isEmpty, "Hourly icon code should not be empty")
        }
        
        // Verify daily forecast (5-day forecast API provides up to 5 days)
        #expect(!dailyForecast.isEmpty, "Daily forecast should not be empty")
        #expect(dailyForecast.count <= 5, "Should return at most 5 daily forecasts")
        #expect(dailyForecast.count >= 3, "Should return at least 3 daily forecasts")
        
        for daily in dailyForecast {
            #expect(daily.temperatureMin > -50, "Daily min temperature should be reasonable")
            #expect(daily.temperatureMax < 150, "Daily max temperature should be reasonable")
            #expect(daily.temperatureMin <= daily.temperatureMax, "Min temp should be <= max temp")
            #expect(!daily.iconCode.isEmpty, "Daily icon code should not be empty")
            #expect(daily.precipitationChance >= 0, "Precipitation chance should be non-negative")
            #expect(daily.precipitationChance <= 1, "Precipitation chance should not exceed 100%")
        }
    }
    
    @Test("Free API comprehensive data returns complete weather information")
    func freeAPIComprehensiveData() async throws {
        // Create a test city
        let testCity = City(
            name: "Austin",
            countryCode: "US",
            latitude: 30.2672,
            longitude: -97.7431
        )
        
        let (weather, hourlyForecast, dailyForecast) = try await repository.getCompleteWeatherData(for: testCity)
        
        // Verify current weather
        #expect(weather.temperature > -50, "Temperature should be reasonable")
        #expect(weather.temperature < 150, "Temperature should be reasonable")
        #expect(!weather.description.isEmpty, "Description should not be empty")
        
        // Verify hourly forecast (5-day forecast provides data every 3 hours)
        #expect(!hourlyForecast.isEmpty, "Hourly forecast should not be empty")
        #expect(hourlyForecast.count <= 40, "Should return at most 40 forecast data points")
        #expect(hourlyForecast.count >= 30, "Should return at least 30 forecast data points")
        
        // Verify that forecast data is every 3 hours (3-hour intervals)
        if hourlyForecast.count >= 2 {
            let firstTime = hourlyForecast[0].time
            let secondTime = hourlyForecast[1].time
            let timeDifference = secondTime.timeIntervalSince(firstTime)
            #expect(abs(timeDifference - 10800) < 60, "Forecast intervals should be 3 hours apart")
        }
        
        // Verify daily forecast (up to 5 days)
        #expect(!dailyForecast.isEmpty, "Daily forecast should not be empty")
        #expect(dailyForecast.count <= 5, "Should return at most 5 daily forecasts")
    }
    
    @Test("API error handling works correctly for invalid coordinates")
    func apiErrorHandling() async throws {
        // Test with invalid coordinates (should trigger city not found)
        let invalidLatitude = 999.0
        let invalidLongitude = 999.0
        
        await #expect(throws: WeatherError.self) {
            _ = try await repository.getCurrentWeather(latitude: invalidLatitude, longitude: invalidLongitude)
        }
    }
}
