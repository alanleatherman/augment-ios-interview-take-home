//
//  WeatherPreviewRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

final class WeatherPreviewRepository: WeatherRepositoryProtocol, @unchecked Sendable {
    private var cities: [City] = []
    private var weatherData: [UUID: Weather] = [:]
    private var hourlyData: [UUID: [HourlyWeather]] = [:]
    private var dailyData: [UUID: [DailyWeather]] = [:]
    
    init() {
        // Initialize with the required default cities per spec
        cities = [
            City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
            City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
            City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
            City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
            City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633)
        ]
        
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
        // Generate realistic weather based on city location and climate
        let (baseTemp, condition, humidity, pressure, windSpeed, visibility) = getRealisticWeatherForCity(city)
        
        return Weather(
            id: UUID(),
            cityId: city.id,
            temperature: baseTemp,
            feelsLike: baseTemp + Double.random(in: -3...5),
            temperatureMin: baseTemp - Double.random(in: 5...10),
            temperatureMax: baseTemp + Double.random(in: 3...8),
            description: condition.description,
            iconCode: condition.iconCode,
            humidity: humidity,
            pressure: pressure,
            windSpeed: windSpeed,
            windDirection: Int.random(in: 0...360),
            visibility: visibility,
            lastUpdated: Date()
        )
    }
    
    private func getRealisticWeatherForCity(_ city: City) -> (temp: Double, condition: (iconCode: String, description: String), humidity: Int, pressure: Int, windSpeed: Double, visibility: Int) {
        switch city.name {
        case "Los Angeles":
            // LA - Sunny and warm, low humidity
            return (75, ("01d", "Sunny"), Int.random(in: 35...55), Int.random(in: 1015...1020), Double.random(in: 3...8), Int.random(in: 12000...15000))
            
        case "San Francisco":
            // SF - Cool and foggy
            return (62, ("50d", "Foggy"), Int.random(in: 75...90), Int.random(in: 1012...1016), Double.random(in: 8...15), Int.random(in: 2000...5000))
            
        case "Austin":
            // Austin - Hot and sunny (Texas heat)
            return (89, ("01d", "Sunny"), Int.random(in: 40...60), Int.random(in: 1013...1018), Double.random(in: 5...12), Int.random(in: 10000...15000))
            
        case "Lisbon":
            // Lisbon - Mild and partly cloudy (Mediterranean climate)
            return (72, ("02d", "Partly cloudy"), Int.random(in: 60...75), Int.random(in: 1014...1019), Double.random(in: 6...12), Int.random(in: 8000...12000))
            
        case "Auckland":
            // Auckland - Mild and overcast (oceanic climate)
            return (65, ("04d", "Overcast"), Int.random(in: 70...85), Int.random(in: 1010...1015), Double.random(in: 8...16), Int.random(in: 6000...10000))
            
        default:
            // Default for any other cities - moderate conditions
            if city.latitude > 50 {
                // Northern cities - cooler and more likely to be cloudy/rainy
                return (58, ("10d", "Light rain"), Int.random(in: 75...90), Int.random(in: 1008...1013), Double.random(in: 10...18), Int.random(in: 5000...8000))
            } else if city.latitude < 25 {
                // Tropical cities - hot and humid
                return (85, ("02d", "Partly cloudy"), Int.random(in: 70...90), Int.random(in: 1012...1017), Double.random(in: 4...10), Int.random(in: 8000...12000))
            } else {
                // Temperate cities - moderate
                return (70, ("03d", "Scattered clouds"), Int.random(in: 50...70), Int.random(in: 1013...1018), Double.random(in: 5...12), Int.random(in: 8000...12000))
            }
        }
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