//
//  MockWeatherRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import Foundation

class MockWeatherRepository: WeatherRepositoryProtocol, @unchecked Sendable {
    // Mock data
    var mockCities: [City] = []
    var mockWeatherResponse: Weather?
    var mockCachedWeather: [UUID: Weather] = [:]
    var mockHourlyForecast: [HourlyWeather] = []
    var mockDailyForecast: [DailyWeather] = []
    
    // Error simulation
    var shouldThrowError = false
    var errorToThrow: WeatherError = .networkFailure(URLError(.notConnectedToInternet))
    
    // Call tracking
    var getCurrentWeatherCalled = false
    var cacheWeatherCalled = false
    var addCityCalled = false
    var removeCityCalled = false
    var getHourlyForecastCalled = false
    var getDailyForecastCalled = false
    var lastAddedCity: City?
    
    // MARK: - WeatherRepositoryProtocol Implementation
    
    func getCurrentWeather(for city: City) async throws -> Weather {
        getCurrentWeatherCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockWeatherResponse ?? Weather(
            id: UUID(),
            cityId: city.id,
            temperature: 72,
            feelsLike: 75,
            temperatureMin: 65,
            temperatureMax: 80,
            description: "Clear",
            iconCode: "01d",
            humidity: 50,
            pressure: 1013,
            windSpeed: 10,
            windDirection: 180,
            visibility: 10000,
            lastUpdated: Date()
        )
    }
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        getCurrentWeatherCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockWeatherResponse ?? Weather(
            id: UUID(),
            cityId: UUID(),
            temperature: 72,
            feelsLike: 75,
            temperatureMin: 65,
            temperatureMax: 80,
            description: "Clear",
            iconCode: "01d",
            humidity: 50,
            pressure: 1013,
            windSpeed: 10,
            windDirection: 180,
            visibility: 10000,
            lastUpdated: Date()
        )
    }
    
    func getCachedWeather(for cityId: UUID) -> Weather? {
        return mockCachedWeather[cityId]
    }
    
    func cacheWeather(_ weather: Weather) {
        cacheWeatherCalled = true
        mockCachedWeather[weather.cityId] = weather
    }
    
    func clearCache() {
        mockCachedWeather.removeAll()
    }
    
    func addCity(_ city: City) async throws {
        addCityCalled = true
        lastAddedCity = city
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCities.append(city)
    }
    
    func removeCity(_ city: City) async throws {
        removeCityCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCities.removeAll { $0.id == city.id }
    }
    
    func getAllCities() async throws -> [City] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockCities
    }
    
    func clearAllData() async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockCities.removeAll()
        mockCachedWeather.removeAll()
    }
    
    func getHourlyForecast(for city: City) async throws -> [HourlyWeather] {
        getHourlyForecastCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockHourlyForecast
    }
    
    func getDailyForecast(for city: City) async throws -> [DailyWeather] {
        getDailyForecastCalled = true
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockDailyForecast
    }
    
    func getCachedHourlyForecast(for cityId: UUID) -> [HourlyWeather]? {
        return nil
    }
    
    func getCachedDailyForecast(for cityId: UUID) -> [DailyWeather]? {
        return nil
    }
    
    func cacheHourlyForecast(_ forecast: [HourlyWeather], for cityId: UUID) {
        // Mock implementation
    }
    
    func cacheDailyForecast(_ forecast: [DailyWeather], for cityId: UUID) {
        // Mock implementation
    }
    
    func getCompleteWeatherData(for city: City) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather]) {
        let weather = try await getCurrentWeather(for: city)
        let hourly = try await getHourlyForecast(for: city)
        let daily = try await getDailyForecast(for: city)
        return (weather: weather, hourly: hourly, daily: daily)
    }
    
    func getCompleteWeatherData(latitude: Double, longitude: Double) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather]) {
        let weather = try await getCurrentWeather(latitude: latitude, longitude: longitude)
        return (weather: weather, hourly: mockHourlyForecast, daily: mockDailyForecast)
    }
    
    func getExtendedForecast(for city: City) async throws -> [DailyWeather] {
        return try await getDailyForecast(for: city)
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        mockCities.removeAll()
        mockWeatherResponse = nil
        mockCachedWeather.removeAll()
        mockHourlyForecast.removeAll()
        mockDailyForecast.removeAll()
        shouldThrowError = false
        errorToThrow = .networkFailure(URLError(.notConnectedToInternet))
        getCurrentWeatherCalled = false
        cacheWeatherCalled = false
        addCityCalled = false
        removeCityCalled = false
        getHourlyForecastCalled = false
        getDailyForecastCalled = false
        lastAddedCity = nil
    }
}