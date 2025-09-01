//
//  WeatherWebRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftData

final class WeatherWebRepository: WeatherRepositoryProtocol, @unchecked Sendable {
    private let apiKey: String
    private let session: URLSession
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil, apiKey: String = "YOUR_API_KEY_HERE") {
        self.modelContext = modelContext
        self.apiKey = apiKey
        self.session = URLSession.shared
    }
    
    // MARK: - Current Weather
    
    func getCurrentWeather(for city: City) async throws -> Weather {
        return try await getCurrentWeather(latitude: city.latitude, longitude: city.longitude)
    }
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        // TODO: Implement actual API call to OpenWeatherMap
        // For now, return sample data
        return Weather.sample
    }
    
    // MARK: - Forecast Data
    
    func getHourlyForecast(for city: City) async throws -> [HourlyWeather] {
        // TODO: Implement API call to OpenWeatherMap 5-day forecast endpoint
        return HourlyWeather.samples
    }
    
    func getDailyForecast(for city: City) async throws -> [DailyWeather] {
        // TODO: Implement API call to OpenWeatherMap 16-day forecast endpoint
        return DailyWeather.samples
    }
    
    func getExtendedForecast(for city: City) async throws -> [DailyWeather] {
        return try await getDailyForecast(for: city)
    }
    
    // MARK: - Caching
    
    @MainActor
    func getCachedWeather(for cityId: UUID) -> Weather? {
        guard let modelContext = modelContext else { return nil }
        
        let now = Date()
        let descriptor = FetchDescriptor<CachedWeather>(
            predicate: #Predicate<CachedWeather> { cachedWeather in
                cachedWeather.cityId == cityId && cachedWeather.expiresAt > now
            }
        )
        
        do {
            let cachedWeather = try modelContext.fetch(descriptor).first
            return cachedWeather?.toWeather()
        } catch {
            return nil
        }
    }
    
    func getCachedHourlyForecast(for cityId: UUID) -> [HourlyWeather]? {
        // For now, return nil - we can implement this later if needed
        return nil
    }
    
    func getCachedDailyForecast(for cityId: UUID) -> [DailyWeather]? {
        // For now, return nil - we can implement this later if needed
        return nil
    }
    
    @MainActor
    func cacheWeather(_ weather: Weather) {
        guard let modelContext = modelContext else { return }
        
        // Remove existing cached weather for this city
        let weatherCityId = weather.cityId
        let descriptor = FetchDescriptor<CachedWeather>(
            predicate: #Predicate<CachedWeather> { cachedWeather in
                cachedWeather.cityId == weatherCityId
            }
        )
        
        do {
            let existingCache = try modelContext.fetch(descriptor)
            for cached in existingCache {
                modelContext.delete(cached)
            }
            
            // Insert new cached weather
            let cachedWeather = CachedWeather(from: weather)
            modelContext.insert(cachedWeather)
            
            try modelContext.save()
        } catch {
            // Silently fail for caching errors
        }
    }
    
    func cacheHourlyForecast(_ forecast: [HourlyWeather], for cityId: UUID) {
        // For now, do nothing - we can implement this later if needed
    }
    
    func cacheDailyForecast(_ forecast: [DailyWeather], for cityId: UUID) {
        // For now, do nothing - we can implement this later if needed
    }
    
    @MainActor
    func clearCache() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<CachedWeather>()
        
        do {
            let cachedWeather = try modelContext.fetch(descriptor)
            for cached in cachedWeather {
                modelContext.delete(cached)
            }
            try modelContext.save()
        } catch {
            // Silently fail for cache clearing errors
        }
    }
    
    // MARK: - City Management
    
    @MainActor
    func addCity(_ city: City) async throws {
        guard let modelContext = modelContext else {
            throw WeatherError.persistenceFailure(NSError(domain: "WeatherApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"]))
        }
        
        modelContext.insert(city)
        
        do {
            try modelContext.save()
        } catch {
            throw WeatherError.persistenceFailure(error)
        }
    }
    
    @MainActor
    func removeCity(_ city: City) async throws {
        guard let modelContext = modelContext else {
            throw WeatherError.persistenceFailure(NSError(domain: "WeatherApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"]))
        }
        
        modelContext.delete(city)
        
        // Clear cached weather data for this city
        let cityId = city.id
        let descriptor = FetchDescriptor<CachedWeather>(
            predicate: #Predicate<CachedWeather> { cachedWeather in
                cachedWeather.cityId == cityId
            }
        )
        
        do {
            let cachedWeather = try modelContext.fetch(descriptor)
            for cached in cachedWeather {
                modelContext.delete(cached)
            }
            
            try modelContext.save()
        } catch {
            throw WeatherError.persistenceFailure(error)
        }
    }
    
    @MainActor
    func getAllCities() async throws -> [City] {
        guard let modelContext = modelContext else {
            throw WeatherError.persistenceFailure(NSError(domain: "WeatherApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"]))
        }
        
        let descriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.dateAdded)])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw WeatherError.persistenceFailure(error)
        }
    }
    
    @MainActor
    func clearAllData() async throws {
        guard let modelContext = modelContext else {
            throw WeatherError.persistenceFailure(NSError(domain: "WeatherApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"]))
        }
        
        let cities = try await getAllCities()
        for city in cities {
            modelContext.delete(city)
        }
        
        clearCache()
        
        do {
            try modelContext.save()
        } catch {
            throw WeatherError.persistenceFailure(error)
        }
    }
}
