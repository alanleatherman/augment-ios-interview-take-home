//
//  Weather.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftData

struct Weather: Codable, Identifiable, Sendable {
    let id: UUID
    let cityId: UUID
    let temperature: Double
    let feelsLike: Double
    let temperatureMin: Double
    let temperatureMax: Double
    let description: String
    let iconCode: String
    let humidity: Int
    let pressure: Int
    let windSpeed: Double
    let windDirection: Int
    let visibility: Int
    let lastUpdated: Date
    
    // Computed properties
    var temperatureFormatted: String {
        "\(Int(temperature.rounded()))°"
    }
    
    var temperatureRangeFormatted: String {
        "H:\(Int(temperatureMax.rounded()))° L:\(Int(temperatureMin.rounded()))°"
    }
    
    var iconURL: URL? {
        URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png")
    }
    
    var weatherConditionEmoji: String {
        switch iconCode.prefix(2) {
        case "01": return "☀️"  // Clear sky
        case "02": return "🌤️"  // Few clouds
        case "03": return "⛅"  // Scattered clouds
        case "04": return "☁️"  // Broken clouds
        case "09": return "🌦️"  // Shower rain
        case "10": return "🌧️"  // Rain
        case "11": return "⛈️"  // Thunderstorm
        case "13": return "🌨️"  // Snow
        case "50": return "🌫️"  // Mist
        default: return "☀️"
        }
    }
    
    var detailedDescription: String? {
        switch iconCode.prefix(2) {
        case "01": return "Sunny conditions will continue for the rest of the day."
        case "02": return "Partly cloudy conditions with occasional sun breaks."
        case "03", "04": return "Cloudy skies with overcast conditions."
        case "09", "10": return "Rain is expected. Consider bringing an umbrella."
        case "11": return "Thunderstorms possible. Stay indoors if possible."
        case "13": return "Snow is falling. Drive carefully and dress warmly."
        case "50": return "Misty conditions with reduced visibility."
        default: return "Current weather conditions will continue."
        }
    }
}

// MARK: - SwiftData Model for Caching

@Model
final class CachedWeather {
    var id: UUID
    var cityId: UUID
    var temperature: Double
    var feelsLike: Double
    var temperatureMin: Double
    var temperatureMax: Double
    var weatherDescription: String
    var iconCode: String
    var humidity: Int
    var pressure: Int
    var windSpeed: Double
    var windDirection: Int
    var visibility: Int
    var lastUpdated: Date
    var expiresAt: Date
    
    init(from weather: Weather) {
        self.id = weather.id
        self.cityId = weather.cityId
        self.temperature = weather.temperature
        self.feelsLike = weather.feelsLike
        self.temperatureMin = weather.temperatureMin
        self.temperatureMax = weather.temperatureMax
        self.weatherDescription = weather.description
        self.iconCode = weather.iconCode
        self.humidity = weather.humidity
        self.pressure = weather.pressure
        self.windSpeed = weather.windSpeed
        self.windDirection = weather.windDirection
        self.visibility = weather.visibility
        self.lastUpdated = weather.lastUpdated
        self.expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
    }
    
    func toWeather() -> Weather {
        Weather(
            id: id,
            cityId: cityId,
            temperature: temperature,
            feelsLike: feelsLike,
            temperatureMin: temperatureMin,
            temperatureMax: temperatureMax,
            description: weatherDescription,
            iconCode: iconCode,
            humidity: humidity,
            pressure: pressure,
            windSpeed: windSpeed,
            windDirection: windDirection,
            visibility: visibility,
            lastUpdated: lastUpdated
        )
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Sample Data

extension Weather {
    static let sample = Weather(
        id: UUID(),
        cityId: City.sample.id,
        temperature: 72,
        feelsLike: 75,
        temperatureMin: 61,
        temperatureMax: 76,
        description: "Sunny",
        iconCode: "01d",
        humidity: 65,
        pressure: 1013,
        windSpeed: 12,
        windDirection: 270,
        visibility: 10000,
        lastUpdated: Date()
    )
}