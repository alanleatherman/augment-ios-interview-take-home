//
//  WeatherAPITests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Kiro on 9/1/25.
//

import XCTest
@testable import augment_ios_interview_take_home

final class WeatherAPITests: XCTestCase {
    
    var repository: WeatherWebRepository!
    
    override func setUp() {
        super.setUp()
        let appSettings = AppSettings()
        repository = WeatherWebRepository(appSettings: appSettings)
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testCurrentWeatherAPI() async throws {
        // Test with San Francisco coordinates
        let latitude = 37.7749
        let longitude = -122.4194
        
        do {
            let weather = try await repository.getCurrentWeather(latitude: latitude, longitude: longitude)
            
            // Verify we got valid weather data
            XCTAssertGreaterThan(weather.temperature, -50, "Temperature should be reasonable")
            XCTAssertLessThan(weather.temperature, 60, "Temperature should be reasonable")
            XCTAssertFalse(weather.description.isEmpty, "Description should not be empty")
            XCTAssertFalse(weather.iconCode.isEmpty, "Icon code should not be empty")
            XCTAssertGreaterThanOrEqual(weather.humidity, 0, "Humidity should be non-negative")
            XCTAssertLessThanOrEqual(weather.humidity, 100, "Humidity should not exceed 100%")
            XCTAssertGreaterThan(weather.pressure, 800, "Pressure should be reasonable")
            XCTAssertLessThan(weather.pressure, 1200, "Pressure should be reasonable")
            
            print("✅ Current weather API test passed")
            print("Temperature: \(weather.temperature)°C")
            print("Description: \(weather.description)")
            print("Humidity: \(weather.humidity)%")
            print("Pressure: \(weather.pressure) hPa")
            
        } catch {
            XCTFail("Current weather API call failed: \(error)")
        }
    }
    
    func testForecastAPI() async throws {
        // Create a test city
        let testCity = City(
            name: "San Francisco",
            countryCode: "US",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        do {
            let hourlyForecast = try await repository.getHourlyForecast(for: testCity)
            let dailyForecast = try await repository.getDailyForecast(for: testCity)
            
            // Verify hourly forecast
            XCTAssertFalse(hourlyForecast.isEmpty, "Hourly forecast should not be empty")
            XCTAssertLessThanOrEqual(hourlyForecast.count, 8, "Should return at most 8 hourly forecasts")
            
            for hourly in hourlyForecast {
                XCTAssertGreaterThan(hourly.temperature, -50, "Hourly temperature should be reasonable")
                XCTAssertLessThan(hourly.temperature, 60, "Hourly temperature should be reasonable")
                XCTAssertFalse(hourly.iconCode.isEmpty, "Hourly icon code should not be empty")
            }
            
            // Verify daily forecast
            XCTAssertFalse(dailyForecast.isEmpty, "Daily forecast should not be empty")
            XCTAssertLessThanOrEqual(dailyForecast.count, 5, "Should return at most 5 daily forecasts")
            
            for daily in dailyForecast {
                XCTAssertGreaterThan(daily.temperatureMin, -50, "Daily min temperature should be reasonable")
                XCTAssertLessThan(daily.temperatureMax, 60, "Daily max temperature should be reasonable")
                XCTAssertLessThanOrEqual(daily.temperatureMin, daily.temperatureMax, "Min temp should be <= max temp")
                XCTAssertFalse(daily.iconCode.isEmpty, "Daily icon code should not be empty")
                XCTAssertGreaterThanOrEqual(daily.precipitationChance, 0, "Precipitation chance should be non-negative")
                XCTAssertLessThanOrEqual(daily.precipitationChance, 1, "Precipitation chance should not exceed 100%")
            }
            
            print("✅ Forecast API test passed")
            print("Hourly forecasts: \(hourlyForecast.count)")
            print("Daily forecasts: \(dailyForecast.count)")
            
        } catch {
            XCTFail("Forecast API call failed: \(error)")
        }
    }
    
    func testAPIErrorHandling() async {
        // Test with invalid coordinates (should trigger city not found)
        let invalidLatitude = 999.0
        let invalidLongitude = 999.0
        
        do {
            _ = try await repository.getCurrentWeather(latitude: invalidLatitude, longitude: invalidLongitude)
            XCTFail("Should have thrown an error for invalid coordinates")
        } catch let error as WeatherError {
            switch error {
            case .cityNotFound, .networkFailure, .malformedResponse:
                print("✅ Error handling test passed: \(error)")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}