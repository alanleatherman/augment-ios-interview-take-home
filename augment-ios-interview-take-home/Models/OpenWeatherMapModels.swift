//
//  OpenWeatherMapModels.swift
//  augment-ios-interview-take-home
//
//  Created by Kiro on 9/1/25.
//

import Foundation

// MARK: - Shared Data Structures

struct Coordinates: Codable {
    let lon: Double
    let lat: Double
}

struct WeatherCondition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeatherData: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    let seaLevel: Int?
    let grndLevel: Int?
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct WindData: Codable {
    let speed: Double
    let deg: Int?
    let gust: Double?
}

struct CloudData: Codable {
    let all: Int
}

// MARK: - Current Weather API Response

struct OpenWeatherMapCurrentResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherCondition]
    let main: MainWeatherData
    let visibility: Int
    let wind: WindData
    let clouds: CloudData
    let dt: TimeInterval
    let sys: SystemData
    let timezone: Int
    let id: Int
    let name: String
    let cod: Int
    
    struct SystemData: Codable {
        let type: Int?
        let id: Int?
        let country: String
        let sunrise: TimeInterval
        let sunset: TimeInterval
    }
}

// MARK: - Forecast API Response

struct OpenWeatherMapForecastResponse: Codable {
    let cod: String
    let message: Int
    let cnt: Int
    let list: [ForecastItem]
    let city: CityInfo
}

struct ForecastItem: Codable {
    let dt: TimeInterval
    let main: MainWeatherData
    let weather: [WeatherCondition]
    let clouds: CloudData
    let wind: WindData
    let visibility: Int
    let pop: Double // Probability of precipitation
    let sys: SystemInfo
    let dtTxt: String
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, sys
        case dtTxt = "dt_txt"
    }
}

struct SystemInfo: Codable {
    let pod: String // Part of day (d/n)
}

struct CityInfo: Codable {
    let id: Int
    let name: String
    let coord: Coordinates
    let country: String
    let population: Int?
    let timezone: Int
    let sunrise: TimeInterval
    let sunset: TimeInterval
}

// MARK: - Conversion Extensions

extension OpenWeatherMapCurrentResponse {
    func toWeather(for cityId: UUID) -> Weather {
        let primaryWeather = weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
        
        return Weather(
            id: UUID(),
            cityId: cityId,
            temperature: main.temp,
            feelsLike: main.feelsLike,
            temperatureMin: main.tempMin,
            temperatureMax: main.tempMax,
            description: primaryWeather.description.capitalized,
            iconCode: primaryWeather.icon,
            humidity: main.humidity,
            pressure: main.pressure,
            windSpeed: wind.speed,
            windDirection: wind.deg ?? 0,
            visibility: visibility,
            lastUpdated: Date()
        )
    }
}

extension ForecastItem {
    func toHourlyWeather() -> HourlyWeather {
        let primaryWeather = weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
        
        return HourlyWeather(
            id: UUID(),
            time: Date(timeIntervalSince1970: dt),
            temperature: main.temp,
            iconCode: primaryWeather.icon,
            description: primaryWeather.description.capitalized
        )
    }
}

extension Array where Element == ForecastItem {
    func toDailyWeather() -> [DailyWeather] {
        // Group forecast items by day
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { item in
            calendar.startOfDay(for: Date(timeIntervalSince1970: item.dt))
        }
        
        return grouped.compactMap { (date, items) -> DailyWeather? in
            guard !items.isEmpty else { return nil }
            
            let temps = items.map { $0.main.temp }
            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 0
            
            // Use the weather condition from the middle of the day (around noon)
            let noonItem = items.min { abs($0.dt.truncatingRemainder(dividingBy: 86400) - 43200) < abs($1.dt.truncatingRemainder(dividingBy: 86400) - 43200) }
            let primaryWeather = noonItem?.weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
            
            // Calculate average precipitation probability
            let avgPrecipitation = items.map { $0.pop }.reduce(0, +) / Double(items.count)
            
            return DailyWeather(
                id: UUID(),
                date: date,
                temperatureMin: minTemp,
                temperatureMax: maxTemp,
                iconCode: primaryWeather.icon,
                description: primaryWeather.description.capitalized,
                precipitationChance: avgPrecipitation
            )
        }.sorted { $0.date < $1.date }
    }
}