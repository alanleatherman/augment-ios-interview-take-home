//
//  HourlyForecastView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct HourlyForecastView: View {
    let forecast: [HourlyWeather]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(forecast.prefix(12)) { hour in
                        VStack(spacing: 8) {
                            Text(hour.timeFormatted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(hour.weatherEmoji)
                                .font(.title2)
                            
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}