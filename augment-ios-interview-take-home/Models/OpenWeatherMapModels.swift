//
//  OpenWeatherMapModels.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
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

// MARK: - One Call API 3.0 Response

struct OneCallAPIResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let timezoneOffset: Int
    let current: CurrentWeatherData
    let hourly: [HourlyWeatherData]
    let daily: [DailyWeatherData]
    
    enum CodingKeys: String, CodingKey {
        case lat, lon, timezone, current, hourly, daily
        case timezoneOffset = "timezone_offset"
    }
}

struct CurrentWeatherData: Codable {
    let dt: TimeInterval
    let sunrise: TimeInterval?
    let sunset: TimeInterval?
    let temp: Double
    let feelsLike: Double
    let pressure: Int
    let humidity: Int
    let dewPoint: Double?
    let uvi: Double?
    let clouds: Int
    let visibility: Int
    let windSpeed: Double
    let windDeg: Int?
    let windGust: Double?
    let weather: [WeatherCondition]
    
    enum CodingKeys: String, CodingKey {
        case dt, sunrise, sunset, temp, pressure, humidity, clouds, visibility, weather
        case feelsLike = "feels_like"
        case dewPoint = "dew_point"
        case uvi
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
        case windGust = "wind_gust"
    }
}

struct HourlyWeatherData: Codable {
    let dt: TimeInterval
    let temp: Double
    let feelsLike: Double
    let pressure: Int
    let humidity: Int
    let dewPoint: Double?
    let uvi: Double?
    let clouds: Int
    let visibility: Int
    let windSpeed: Double
    let windDeg: Int?
    let windGust: Double?
    let weather: [WeatherCondition]
    let pop: Double // Probability of precipitation
    
    enum CodingKeys: String, CodingKey {
        case dt, temp, pressure, humidity, clouds, visibility, weather, pop
        case feelsLike = "feels_like"
        case dewPoint = "dew_point"
        case uvi
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
        case windGust = "wind_gust"
    }
}

struct DailyWeatherData: Codable {
    let dt: TimeInterval
    let sunrise: TimeInterval
    let sunset: TimeInterval
    let moonrise: TimeInterval?
    let moonset: TimeInterval?
    let moonPhase: Double?
    let summary: String?
    let temp: DailyTemperature
    let feelsLike: DailyFeelsLike
    let pressure: Int
    let humidity: Int
    let dewPoint: Double?
    let windSpeed: Double
    let windDeg: Int?
    let windGust: Double?
    let weather: [WeatherCondition]
    let clouds: Int
    let pop: Double
    let uvi: Double?
    
    enum CodingKeys: String, CodingKey {
        case dt, sunrise, sunset, moonrise, moonset, summary, temp, pressure, humidity, weather, clouds, pop, uvi
        case moonPhase = "moon_phase"
        case feelsLike = "feels_like"
        case dewPoint = "dew_point"
        case windSpeed = "wind_speed"
        case windDeg = "wind_deg"
        case windGust = "wind_gust"
    }
}

struct DailyTemperature: Codable {
    let day: Double
    let min: Double
    let max: Double
    let night: Double
    let eve: Double
    let morn: Double
}

struct DailyFeelsLike: Codable {
    let day: Double
    let night: Double
    let eve: Double
    let morn: Double
}

// MARK: - Conversion Extensions

extension OneCallAPIResponse {
    func toWeather(for cityId: UUID) -> Weather {
        let primaryWeather = current.weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
        
        return Weather(
            id: UUID(),
            cityId: cityId,
            temperature: current.temp,
            feelsLike: current.feelsLike,
            temperatureMin: daily.first?.temp.min ?? current.temp,
            temperatureMax: daily.first?.temp.max ?? current.temp,
            description: primaryWeather.description.capitalized,
            iconCode: primaryWeather.icon,
            humidity: current.humidity,
            pressure: current.pressure,
            windSpeed: current.windSpeed,
            windDirection: current.windDeg ?? 0,
            visibility: current.visibility,
            lastUpdated: Date()
        )
    }
    
    func toHourlyWeather() -> [HourlyWeather] {
        return hourly.prefix(48).map { hourlyData in
            let primaryWeather = hourlyData.weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
            
            return HourlyWeather(
                id: UUID(),
                time: Date(timeIntervalSince1970: hourlyData.dt),
                temperature: hourlyData.temp,
                iconCode: primaryWeather.icon,
                description: primaryWeather.description.capitalized
            )
        }
    }
    
    func toDailyWeather() -> [DailyWeather] {
        return daily.prefix(5).map { dailyData in
            let primaryWeather = dailyData.weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
            
            return DailyWeather(
                id: UUID(),
                date: Date(timeIntervalSince1970: dailyData.dt),
                temperatureMin: dailyData.temp.min,
                temperatureMax: dailyData.temp.max,
                iconCode: primaryWeather.icon,
                description: primaryWeather.description.capitalized,
                precipitationChance: dailyData.pop
            )
        }
    }
}

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
    
    // Helper method to create a DailyWeather for today using current weather data
    func toTodaysDailyWeather() -> DailyWeather {
        let primaryWeather = weather.first ?? WeatherCondition(id: 0, main: "Unknown", description: "Unknown", icon: "01d")
        
        return DailyWeather(
            id: UUID(),
            date: Date(),
            temperatureMin: main.tempMin,
            temperatureMax: main.tempMax,
            iconCode: primaryWeather.icon,
            description: primaryWeather.description.capitalized,
            precipitationChance: 0.0 // Current weather doesn't include precipitation chance
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
        }.sorted { $0.date < $1.date }.prefix(5).map { $0 }
    }
}
