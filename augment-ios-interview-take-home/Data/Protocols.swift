//
//  Protocols.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

// MARK: - Weather Repository Protocol

protocol WeatherRepositoryProtocol: Sendable {
    // Current weather
    func getCurrentWeather(for city: City) async throws -> Weather
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather
    
    // Forecast data
    func getHourlyForecast(for city: City) async throws -> [HourlyWeather]
    func getDailyForecast(for city: City) async throws -> [DailyWeather]
    func getExtendedForecast(for city: City) async throws -> [DailyWeather]
    
    // One Call API methods (comprehensive weather data)
    func getCompleteWeatherData(for city: City) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather])
    func getCompleteWeatherData(latitude: Double, longitude: Double) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather])
    
    // Caching
    @MainActor func getCachedWeather(for cityId: UUID) -> Weather?
    func getCachedHourlyForecast(for cityId: UUID) -> [HourlyWeather]?
    func getCachedDailyForecast(for cityId: UUID) -> [DailyWeather]?
    @MainActor func cacheWeather(_ weather: Weather)
    func cacheHourlyForecast(_ forecast: [HourlyWeather], for cityId: UUID)
    func cacheDailyForecast(_ forecast: [DailyWeather], for cityId: UUID)
    @MainActor func clearCache()
    
    // City management
    @MainActor func addCity(_ city: City) async throws
    @MainActor func removeCity(_ city: City) async throws
    @MainActor func getAllCities() async throws -> [City]
    @MainActor func clearAllData() async throws
}

// MARK: - Location Repository Protocol

protocol LocationRepositoryProtocol: Sendable {
    func requestLocationPermission() async
    func getCurrentLocation() async throws -> CLLocation
    func getAuthorizationStatus() -> CLAuthorizationStatus
}

// MARK: - Interactor Protocols

protocol WeatherInteractorProtocol {
    func loadInitialData() async
    func addCity(_ city: City) async
    func removeCity(_ city: City) async
    func refreshWeather(for city: City) async
    func refreshAllWeather() async
    func clearAllData() async
    
    // Forecast methods
    func loadHourlyForecast(for city: City) async
    func loadDailyForecast(for city: City) async
    
    // Selected city management
    func updateSelectedCityIndex(_ index: Int)
    
    // Home city management
    func markCurrentCityAsHome()
    func clearHomeCity()
    func isHomeCity(_ city: City) -> Bool
}

protocol LocationInteractorProtocol {
    func requestLocationPermission() async
    func getCurrentLocation() async throws -> CLLocation
    func checkLocationPermission() -> Bool
}
