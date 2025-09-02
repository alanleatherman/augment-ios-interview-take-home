//
//  WeatherForecast.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation

struct HourlyWeather: Codable, Identifiable, Sendable {
    let id: UUID
    let time: Date
    let temperature: Double
    let iconCode: String
    let description: String
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(time) {
            formatter.dateFormat = "ha"
        } else {
            formatter.dateFormat = "E ha"
        }
        
        return formatter.string(from: time).lowercased()
    }
    
    var weatherEmoji: String {
        switch iconCode.prefix(2) {
        case "01": return "☀️"
        case "02": return "🌤️"
        case "03": return "⛅"
        case "04": return "☁️"
        case "09": return "🌦️"
        case "10": return "🌧️"
        case "11": return "⛈️"
        case "13": return "🌨️"
        case "50": return "🌫️"
        default: return "☀️"
        }
    }
}

struct DailyWeather: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let temperatureMin: Double
    let temperatureMax: Double
    let iconCode: String
    let description: String
    let precipitationChance: Double
    
    var dayFormatted: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            // Use abbreviated day name instead of "Tomorrow" to prevent text wrapping
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        }
    }
    
    var temperatureRangeFormatted: String {
        "\(Int(temperatureMin.rounded()))° - \(Int(temperatureMax.rounded()))°"
    }
    
    var weatherEmoji: String {
        switch iconCode.prefix(2) {
        case "01": return "☀️"
        case "02": return "🌤️"
        case "03": return "⛅"
        case "04": return "☁️"
        case "09": return "🌦️"
        case "10": return "🌧️"
        case "11": return "⛈️"
        case "13": return "🌨️"
        case "50": return "🌫️"
        default: return "☀️"
        }
    }
}

// MARK: - Sample Data

extension HourlyWeather {
    static let samples = [
        HourlyWeather(id: UUID(), time: Date(), temperature: 73, iconCode: "01d", description: "Sunny"),
        HourlyWeather(id: UUID(), time: Date().addingTimeInterval(3600), temperature: 71, iconCode: "01d", description: "Sunny"),
        HourlyWeather(id: UUID(), time: Date().addingTimeInterval(7200), temperature: 68, iconCode: "02n", description: "Clear"),
        HourlyWeather(id: UUID(), time: Date().addingTimeInterval(10800), temperature: 66, iconCode: "02n", description: "Clear"),
        HourlyWeather(id: UUID(), time: Date().addingTimeInterval(14400), temperature: 65, iconCode: "02n", description: "Clear")
    ]
}

extension DailyWeather {
    static let samples = [
        DailyWeather(id: UUID(), date: Date(), temperatureMin: 61, temperatureMax: 76, iconCode: "01d", description: "Sunny", precipitationChance: 0.0),
        DailyWeather(id: UUID(), date: Date().addingTimeInterval(86400), temperatureMin: 59, temperatureMax: 76, iconCode: "01d", description: "Sunny", precipitationChance: 0.0),
        DailyWeather(id: UUID(), date: Date().addingTimeInterval(172800), temperatureMin: 59, temperatureMax: 71, iconCode: "03d", description: "Cloudy", precipitationChance: 0.2),
        DailyWeather(id: UUID(), date: Date().addingTimeInterval(259200), temperatureMin: 57, temperatureMax: 68, iconCode: "10d", description: "Rain", precipitationChance: 0.8),
        DailyWeather(id: UUID(), date: Date().addingTimeInterval(345600), temperatureMin: 60, temperatureMax: 74, iconCode: "01d", description: "Sunny", precipitationChance: 0.1)
    ]
}