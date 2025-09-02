//
//  CurrentWeatherCard.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct CurrentWeatherCard: View {
    let weather: Weather
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(weather.temperatureFormatted)
                    .font(.system(size: 72, weight: .thin))
                
                Text(weather.description.capitalized)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(weather.temperatureRangeFormatted)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WeatherDetailItem(title: "Feels Like", value: "\(Int(weather.feelsLike.rounded()))°")
                WeatherDetailItem(title: "Humidity", value: "\(weather.humidity)%")
                WeatherDetailItem(title: "Wind", value: "\(Int(weather.windSpeed.rounded())) mph")
                WeatherDetailItem(title: "Pressure", value: "\(weather.pressure) hPa")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}
