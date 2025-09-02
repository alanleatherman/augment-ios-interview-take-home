//
//  WeatherWebRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftData

final class WeatherWebRepository: WeatherRepositoryProtocol, @unchecked Sendable {
    private let networkService: NetworkService
    private var modelContext: ModelContext?
    private let appSettings: AppSettings
    
    init(modelContext: ModelContext? = nil, networkService: NetworkService = NetworkService.shared, appSettings: AppSettings) {
        self.modelContext = modelContext
        self.networkService = networkService
        self.appSettings = appSettings
    }
    
    // MARK: - Current Weather
    
    func getCurrentWeather(for city: City) async throws -> Weather {
        var components = URLComponents(string: APIConfiguration.URLs.currentWeather)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(city.latitude)),
            URLQueryItem(name: "lon", value: String(city.longitude)),
            URLQueryItem(name: "appid", value: APIConfiguration.shared.openWeatherMapAPIKey),
            URLQueryItem(name: "units", value: appSettings.temperatureUnit.rawValue)
        ]
        
        guard let url = components.url else {
            print("❌ Failed to create URL for weather request")
            throw WeatherError.malformedResponse
        }
        
        print("🌐 Fetching weather for \(city.name) at \(city.latitude), \(city.longitude)")
        print("🌐 URL: \(url.absoluteString)")
        
        do {
            let response = try await networkService.fetch(OpenWeatherMapCurrentResponse.self, from: url)
            print("✅ Successfully fetched weather for \(city.name): \(response.name)")
            return response.toWeather(for: city.id)
        } catch {
            print("❌ Failed to fetch weather for \(city.name): \(error)")
            throw error
        }
    }
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        var components = URLComponents(string: APIConfiguration.URLs.currentWeather)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: APIConfiguration.shared.openWeatherMapAPIKey),
            URLQueryItem(name: "units", value: appSettings.temperatureUnit.rawValue)
        ]
        
        guard let url = components.url else {
            print("❌ Failed to create URL for coordinate-based weather request")
            throw WeatherError.malformedResponse
        }
        
        print("🌐 Fetching weather for coordinates \(latitude), \(longitude)")
        print("🌐 URL: \(url.absoluteString)")
        
        do {
            let response = try await networkService.fetch(OpenWeatherMapCurrentResponse.self, from: url)
            print("✅ Successfully fetched weather for coordinates: \(response.name)")
            
            // Create a temporary city ID for coordinate-based requests
            let cityId = UUID()
            return response.toWeather(for: cityId)
        } catch {
            print("❌ Failed to fetch weather for coordinates \(latitude), \(longitude): \(error)")
            throw error
        }
    }
    
    // MARK: - Forecast Data (5-day Forecast API)
    
    func getHourlyForecast(for city: City) async throws -> [HourlyWeather] {
        let forecastResponse = try await getForecastData(for: city)
        return forecastResponse.list.map { $0.toHourlyWeather() }
    }
    
    func getDailyForecast(for city: City) async throws -> [DailyWeather] {
        let forecastResponse = try await getForecastData(for: city)
        var dailyForecast = forecastResponse.list.toDailyWeather()
        
        // Replace today's forecast with current weather data for more accuracy
        if !dailyForecast.isEmpty {
            do {
                let currentWeatherData = try await getCurrentWeather(for: city)
                let todayFromCurrent = DailyWeather(
                    id: UUID(),
                    date: Date(),
                    temperatureMin: currentWeatherData.temperatureMin,
                    temperatureMax: currentWeatherData.temperatureMax,
                    iconCode: currentWeatherData.iconCode,
                    description: currentWeatherData.description,
                    precipitationChance: 0.0 // Current weather doesn't include precipitation chance
                )
                dailyForecast[0] = todayFromCurrent
                
                print("🌤️ Generated daily forecast with \(dailyForecast.count) days for \(city.name)")
                print("🌤️ Today's forecast (from current weather): H:\(Int(todayFromCurrent.temperatureMax))° L:\(Int(todayFromCurrent.temperatureMin))°")
            } catch {
                print("🌤️ Failed to get current weather for today's forecast, using calculated forecast")
                if let today = dailyForecast.first {
                    print("🌤️ Today's forecast (calculated): H:\(Int(today.temperatureMax))° L:\(Int(today.temperatureMin))°")
                }
            }
        }
        
        return dailyForecast
    }
    
    private func getForecastData(for city: City) async throws -> OpenWeatherMapForecastResponse {
        var components = URLComponents(string: APIConfiguration.URLs.forecast)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(city.latitude)),
            URLQueryItem(name: "lon", value: String(city.longitude)),
            URLQueryItem(name: "appid", value: APIConfiguration.shared.openWeatherMapAPIKey),
            URLQueryItem(name: "units", value: appSettings.temperatureUnit.rawValue)
        ]
        
        guard let url = components.url else {
            throw WeatherError.malformedResponse
        }
        
        return try await networkService.fetch(OpenWeatherMapForecastResponse.self, from: url)
    }
    
    private func getForecastData(latitude: Double, longitude: Double) async throws -> OpenWeatherMapForecastResponse {
        var components = URLComponents(string: APIConfiguration.URLs.forecast)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: APIConfiguration.shared.openWeatherMapAPIKey),
            URLQueryItem(name: "units", value: appSettings.temperatureUnit.rawValue)
        ]
        
        guard let url = components.url else {
            throw WeatherError.malformedResponse
        }
        
        return try await networkService.fetch(OpenWeatherMapForecastResponse.self, from: url)
    }
    
    // MARK: - Combined Weather Data Methods
    
    func getCompleteWeatherData(for city: City) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather]) {
        // Use separate API calls for current weather and forecast
        async let currentWeather = getCurrentWeather(for: city)
        async let forecastData = getForecastData(for: city)
        
        let weather = try await currentWeather
        let forecast = try await forecastData
        let hourlyForecast = forecast.list.map { $0.toHourlyWeather() }
        let dailyForecast = forecast.list.toDailyWeather()
        
        return (weather: weather, hourly: hourlyForecast, daily: dailyForecast)
    }
    
    func getCompleteWeatherData(latitude: Double, longitude: Double) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather]) {
        // Use separate API calls for current weather and forecast
        async let currentWeather = getCurrentWeather(latitude: latitude, longitude: longitude)
        async let forecastData = getForecastData(latitude: latitude, longitude: longitude)
        
        let weather = try await currentWeather
        let forecast = try await forecastData
        let hourlyForecast = forecast.list.map { $0.toHourlyWeather() }
        let dailyForecast = forecast.list.toDailyWeather()
        
        return (weather: weather, hourly: hourlyForecast, daily: dailyForecast)
    }
    
    func getExtendedForecast(for city: City) async throws -> [DailyWeather] {
        // 5-day forecast API provides up to 5 days of daily forecast
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
