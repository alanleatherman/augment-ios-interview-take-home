//
//  WeatherThemeTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import SwiftUI
@testable import augment_ios_interview_take_home

struct WeatherThemeTests {
    
    @Test("Weather background selection works for different conditions")
    func weatherBackgroundSelection() {
        // Test sunny weather
        let sunnyWeather = Weather(
            id: UUID(),
            cityId: UUID(),
            temperature: 75,
            feelsLike: 78,
            temperatureMin: 68,
            temperatureMax: 82,
            description: "Clear sky",
            iconCode: "01d",
            humidity: 45,
            pressure: 1013,
            windSpeed: 5.0,
            windDirection: 180,
            visibility: 10000,
            lastUpdated: Date()
        )
        
        let sunnyGradient = WeatherTheme.backgroundGradient(for: sunnyWeather)
        #expect(sunnyGradient != nil, "Should produce a valid gradient for sunny weather")
        
        // Test cloudy weather
        let cloudyWeather = Weather(
            id: UUID(),
            cityId: UUID(),
            temperature: 65,
            feelsLike: 62,
            temperatureMin: 58,
            temperatureMax: 70,
            description: "Overcast clouds",
            iconCode: "04d",
            humidity: 75,
            pressure: 1008,
            windSpeed: 12.0,
            windDirection: 220,
            visibility: 8000,
            lastUpdated: Date()
        )
        
        let cloudyGradient = WeatherTheme.backgroundGradient(for: cloudyWeather)
        #expect(cloudyGradient != nil, "Should produce a valid gradient for cloudy weather")
        
        // Test rainy weather
        let rainyWeather = Weather(
            id: UUID(),
            cityId: UUID(),
            temperature: 55,
            feelsLike: 52,
            temperatureMin: 50,
            temperatureMax: 60,
            description: "Light rain",
            iconCode: "10d",
            humidity: 85,
            pressure: 1005,
            windSpeed: 15.0,
            windDirection: 270,
            visibility: 5000,
            lastUpdated: Date()
        )
        
        let rainyGradient = WeatherTheme.backgroundGradient(for: rainyWeather)
        #expect(rainyGradient != nil, "Should produce a valid gradient for rainy weather")
        
        // Test snowy weather
        let snowyWeather = Weather(
            id: UUID(),
            cityId: UUID(),
            temperature: 28,
            feelsLike: 22,
            temperatureMin: 25,
            temperatureMax: 32,
            description: "Snow",
            iconCode: "13d",
            humidity: 90,
            pressure: 1000,
            windSpeed: 18.0,
            windDirection: 315,
            visibility: 3000,
            lastUpdated: Date()
        )
        
        let snowyGradient = WeatherTheme.backgroundGradient(for: snowyWeather)
        #expect(snowyGradient != nil, "Should produce a valid gradient for snowy weather")
    }
    
    @Test("Text color selection works correctly")
    func textColorSelection() {
        let snowyWeather = Weather(
            id: UUID(), cityId: UUID(), temperature: 28, feelsLike: 22,
            temperatureMin: 25, temperatureMax: 32, description: "Snow", iconCode: "13d",
            humidity: 90, pressure: 1000, windSpeed: 18.0, windDirection: 315,
            visibility: 3000, lastUpdated: Date()
        )
        
        let sunnyWeather = Weather(
            id: UUID(), cityId: UUID(), temperature: 75, feelsLike: 78,
            temperatureMin: 68, temperatureMax: 82, description: "Clear sky", iconCode: "01d",
            humidity: 45, pressure: 1013, windSpeed: 5.0, windDirection: 180,
            visibility: 10000, lastUpdated: Date()
        )
        
        let snowyTextColor = WeatherTheme.textColor(for: snowyWeather)
        let sunnyTextColor = WeatherTheme.textColor(for: sunnyWeather)
        
        #expect(snowyTextColor != Color.white, "Snowy weather should not use white text")
        #expect(sunnyTextColor == Color.white, "Sunny weather should use white text")
    }
    
    @Test("Icon code mapping produces valid gradients")
    func iconCodeMapping() {
        let testCodes = ["01d", "04d", "10d", "13d", "99x"] // Sample of different weather types + unknown
        
        for iconCode in testCodes {
            let gradient = WeatherTheme.backgroundGradient(for: iconCode)
            #expect(gradient != nil, "Should produce valid gradient for \(iconCode)")
        }
    }
}