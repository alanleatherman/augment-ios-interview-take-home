//
//  WeatherPreviewRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

final class WeatherPreviewRepository: WeatherRepositoryProtocol, @unchecked Sendable {
    private var cities: [City] = City.predefinedCities
    private var weatherData: [UUID: Weather] = [:]
    private var hourlyData: [UUID: [HourlyWeather]] = [:]
    private var dailyData: [UUID: [DailyWeather]] = [:]
    
    init() {
        // Pre-populate with sample data
        for city in cities {
            weatherData[city.id] = generateSampleWeather(for: city)
            hourlyData[city.id] = generateSampleHourlyForecast()
            dailyData[city.id] = generateSampleDailyForecast()
        }
    }
    
    // MARK: - Current Weather
    
    func getCurrentWeather(for city: City) async throws -> Weather {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let existing = weatherData[city.id] {
            return existing
        }
        
        let weather = generateSampleWeather(for: city)
        weatherData[city.id] = weather
        return weather
    }
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        // Find closest city or create a new one
        let city = City(
            name: "Current Location",
            countryCode: "US",
            latitude: latitude,
            longitude: longitude,
            isCurrentLocation: true
        )
        
        return try await getCurrentWeather(for: city)
    }
    
    // MARK: - Forecast Data
    
    func getHourlyForecast(for city: City) async throws -> [HourlyWeather] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        if let existing = hourlyData[city.id] {
            return existing
        }
        
        let forecast = generateSampleHourlyForecast()
        hourlyData[city.id] = forecast
        return forecast
    }
    
    func getDailyForecast(for city: City) async throws -> [DailyWeather] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        if let existing = dailyData[city.id] {
            return existing
        }
        
        let forecast = generateSampleDailyForecast()
        dailyData[city.id] = forecast
        return forecast
    }
    
    func getExtendedForecast(for city: City) async throws -> [DailyWeather] {
        return try await getDailyForecast(for: city)
    }
    
    // MARK: - One Call API Methods (comprehensive weather data)
    
    func getCompleteWeatherData(for city: City) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather]) {
        // Simulate network delay for comprehensive data fetch
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        let weather = try await getCurrentWeather(for: city)
        let hourly = try await getHourlyForecast(for: city)
        let daily = try await getDailyForecast(for: city)
        
        return (weather: weather, hourly: hourly, daily: daily)
    }
    
    func getCompleteWeatherData(latitude: Double, longitude: Double) async throws -> (weather: Weather, hourly: [HourlyWeather], daily: [DailyWeather]) {
        let city = City(
            name: "Current Location",
            countryCode: "US",
            latitude: latitude,
            longitude: longitude,
            isCurrentLocation: true
        )
        
        return try await getCompleteWeatherData(for: city)
    }
    
    // MARK: - Caching (No-op for preview)
    
    @MainActor
    func getCachedWeather(for cityId: UUID) -> Weather? {
        return weatherData[cityId]
    }
    
    func getCachedHourlyForecast(for cityId: UUID) -> [HourlyWeather]? {
        return hourlyData[cityId]
    }
    
    func getCachedDailyForecast(for cityId: UUID) -> [DailyWeather]? {
        return dailyData[cityId]
    }
    
    @MainActor
    func cacheWeather(_ weather: Weather) {
        weatherData[weather.cityId] = weather
    }
    
    func cacheHourlyForecast(_ forecast: [HourlyWeather], for cityId: UUID) {
        hourlyData[cityId] = forecast
    }
    
    func cacheDailyForecast(_ forecast: [DailyWeather], for cityId: UUID) {
        dailyData[cityId] = forecast
    }
    
    @MainActor
    func clearCache() {
        weatherData.removeAll()
        hourlyData.removeAll()
        dailyData.removeAll()
    }
    
    // MARK: - City Management
    
    @MainActor
    func addCity(_ city: City) async throws {
        cities.append(city)
        weatherData[city.id] = generateSampleWeather(for: city)
        hourlyData[city.id] = generateSampleHourlyForecast()
        dailyData[city.id] = generateSampleDailyForecast()
    }
    
    @MainActor
    func removeCity(_ city: City) async throws {
        cities.removeAll { $0.id == city.id }
        weatherData.removeValue(forKey: city.id)
        hourlyData.removeValue(forKey: city.id)
        dailyData.removeValue(forKey: city.id)
    }
    
    @MainActor
    func getAllCities() async throws -> [City] {
        return cities
    }
    
    @MainActor
    func clearAllData() async throws {
        cities.removeAll()
        weatherData.removeAll()
        hourlyData.removeAll()
        dailyData.removeAll()
    }
    
    // MARK: - Sample Data Generation
    
    private func generateSampleWeather(for city: City) -> Weather {
        let baseTemp = Double.random(in: 60...80)
        let conditions = ["01d", "02d", "03d", "04d", "09d", "10d", "11d", "13d", "50d"]
        let descriptions = ["Sunny", "Partly Cloudy", "Cloudy", "Overcast", "Light Rain", "Rain", "Thunderstorm", "Snow", "Foggy"]
        
        let randomIndex = Int.random(in: 0..<conditions.count)
        
        return Weather(
            id: UUID(),
            cityId: city.id,
            temperature: baseTemp,
            feelsLike: baseTemp + Double.random(in: -3...5),
            temperatureMin: baseTemp - Double.random(in: 5...10),
            temperatureMax: baseTemp + Double.random(in: 3...8),
            description: descriptions[randomIndex],
            iconCode: conditions[randomIndex],
            humidity: Int.random(in: 40...90),
            pressure: Int.random(in: 1000...1020),
            windSpeed: Double.random(in: 0...20),
            windDirection: Int.random(in: 0...360),
            visibility: Int.random(in: 5000...15000),
            lastUpdated: Date()
        )
    }
    
    private func generateSampleHourlyForecast() -> [HourlyWeather] {
        var forecast: [HourlyWeather] = []
        let baseTemp = Double.random(in: 60...80)
        let conditions = ["01d", "02d", "03d", "04d", "09d", "10d"]
        let descriptions = ["Sunny", "Partly Cloudy", "Cloudy", "Overcast", "Light Rain", "Rain"]
        
        // Generate 48 hours of true hourly data (as per One Call API 3.0 spec)
        for i in 0..<48 {
            let time = Date().addingTimeInterval(TimeInterval(i * 3600)) // Every hour
            let tempVariation = Double.random(in: -5...5)
            let randomIndex = Int.random(in: 0..<conditions.count)
            
            // Adjust icon for day/night cycle
            let hour = Calendar.current.component(.hour, from: time)
            var iconCode = conditions[randomIndex]
            if hour < 6 || hour > 18 {
                // Convert day icons to night icons
                iconCode = iconCode.replacingOccurrences(of: "d", with: "n")
            }
            
            forecast.append(HourlyWeather(
                id: UUID(),
                time: time,
                temperature: baseTemp + tempVariation,
                iconCode: iconCode,
                description: descriptions[randomIndex]
            ))
        }
        
        return forecast
    }
    
    private func generateSampleDailyForecast() -> [DailyWeather] {
        var forecast: [DailyWeather] = []
        let baseTemp = Double.random(in: 60...80)
        let conditions = ["01d", "02d", "03d", "04d", "09d", "10d", "11d"]
        let descriptions = ["Sunny", "Partly Cloudy", "Cloudy", "Overcast", "Light Rain", "Rain", "Thunderstorm"]
        
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let tempVariation = Double.random(in: -10...10)
            let randomIndex = Int.random(in: 0..<conditions.count)
            
            forecast.append(DailyWeather(
                id: UUID(),
                date: date,
                temperatureMin: baseTemp + tempVariation - Double.random(in: 5...10),
                temperatureMax: baseTemp + tempVariation + Double.random(in: 3...8),
                iconCode: conditions[randomIndex],
                description: descriptions[randomIndex],
                precipitationChance: Double.random(in: 0...1)
            ))
        }
        
        return forecast
    }
}