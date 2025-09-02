//
//  WeatherTheme.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import SwiftUI

// MARK: - Weather Theme System

struct WeatherTheme {
    
    // MARK: - Weather-Specific Background Gradients
    
    struct Backgrounds {
        // Sunny/Clear conditions
        static let sunny = LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.8, blue: 0.4),    // Warm yellow
                Color(red: 1.0, green: 0.6, blue: 0.2),    // Orange
                Color(red: 0.4, green: 0.7, blue: 1.0)     // Light blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Partly cloudy conditions
        static let partlyCloudy = LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.8, blue: 1.0),    // Light blue
                Color(red: 0.5, green: 0.7, blue: 0.9),    // Medium blue
                Color(red: 0.7, green: 0.7, blue: 0.8)     // Light gray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Cloudy/Overcast conditions
        static let cloudy = LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.6, blue: 0.7),    // Cool gray
                Color(red: 0.5, green: 0.5, blue: 0.6),    // Medium gray
                Color(red: 0.4, green: 0.5, blue: 0.6)     // Blue-gray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Rainy conditions
        static let rainy = LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.3, blue: 0.5),    // Deep blue
                Color(red: 0.3, green: 0.4, blue: 0.6),    // Medium blue
                Color(red: 0.4, green: 0.4, blue: 0.5)     // Blue-gray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Stormy/Thunderstorm conditions
        static let stormy = LinearGradient(
            colors: [
                Color(red: 0.2, green: 0.2, blue: 0.3),    // Dark gray
                Color(red: 0.1, green: 0.2, blue: 0.4),    // Deep blue
                Color(red: 0.3, green: 0.3, blue: 0.4)     // Storm gray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Snowy conditions
        static let snowy = LinearGradient(
            colors: [
                Color(red: 0.9, green: 0.9, blue: 0.95),   // Cool white
                Color(red: 0.8, green: 0.8, blue: 0.9),    // Light gray
                Color(red: 0.7, green: 0.8, blue: 0.9)     // Icy blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Foggy/Misty conditions
        static let foggy = LinearGradient(
            colors: [
                Color(red: 0.8, green: 0.8, blue: 0.8),    // Soft gray
                Color(red: 0.7, green: 0.7, blue: 0.75),   // Muted gray
                Color(red: 0.6, green: 0.65, blue: 0.7)    // Cool gray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Default fallback
        static let `default` = cloudy
    }
    
    // MARK: - Weather Background Selection Logic
    
    static func backgroundGradient(for weather: Weather) -> LinearGradient {
        return backgroundGradient(for: weather.iconCode)
    }
    
    static func backgroundGradient(for iconCode: String) -> LinearGradient {
        let code = iconCode.prefix(2)
        
        switch code {
        case "01": // Clear sky
            return Backgrounds.sunny
        case "02": // Few clouds
            return Backgrounds.partlyCloudy
        case "03": // Scattered clouds
            return Backgrounds.partlyCloudy
        case "04": // Broken clouds
            return Backgrounds.cloudy
        case "09": // Shower rain
            return Backgrounds.rainy
        case "10": // Rain
            return Backgrounds.rainy
        case "11": // Thunderstorm
            return Backgrounds.stormy
        case "13": // Snow
            return Backgrounds.snowy
        case "50": // Mist/Fog
            return Backgrounds.foggy
        default:
            return Backgrounds.default
        }
    }
    
    // MARK: - Text Color Optimization for Readability
    
    static func textColor(for weather: Weather) -> Color {
        return textColor(for: weather.iconCode)
    }
    
    static func textColor(for iconCode: String) -> Color {
        // Use white text for all weather conditions for consistency
        return Color.white
    }
    
    static func secondaryTextColor(for weather: Weather) -> Color {
        return secondaryTextColor(for: weather.iconCode)
    }
    
    static func secondaryTextColor(for iconCode: String) -> Color {
        // Use white text with opacity for all weather conditions for consistency
        return Color.white.opacity(0.8)
    }
    
    // MARK: - Animation Support
    
    struct Animation {
        static let backgroundTransition = SwiftUI.Animation.easeInOut(duration: 0.8)
        static let weatherChange = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }
}

// MARK: - View Extensions for Weather Theming

extension View {
    func weatherBackground(for weather: Weather?) -> some View {
        self.background(
            Group {
                if let weather = weather {
                    WeatherTheme.backgroundGradient(for: weather)
                        .ignoresSafeArea(.all)
                        .animation(WeatherTheme.Animation.backgroundTransition, value: weather.iconCode)
                } else {
                    WeatherTheme.Backgrounds.default
                        .ignoresSafeArea(.all)
                }
            }
        )
    }
    
    func weatherForegroundColor(for weather: Weather?) -> some View {
        self.foregroundColor(
            weather.map { WeatherTheme.textColor(for: $0) } ?? .white
        )
    }
    
    func weatherSecondaryForegroundColor(for weather: Weather?) -> some View {
        self.foregroundColor(
            weather.map { WeatherTheme.secondaryTextColor(for: $0) } ?? .white.opacity(0.8)
        )
    }
}
