//
//  HourlyForecastCard.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct HourlyForecastCard: View {
    let forecast: [HourlyWeather]
    let weather: Weather?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .weatherSecondaryForegroundColor(for: weather)
                Text("HOURLY FORECAST")
                    .font(.caption)
                    .fontWeight(.medium)
                    .weatherSecondaryForegroundColor(for: weather)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecast.prefix(24)) { hour in
                        VStack(spacing: 8) {
                            Text(hour.timeFormatted)
                                .font(.caption)
                                .weatherSecondaryForegroundColor(for: weather)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                            
                            Text(hour.weatherEmoji)
                                .font(.title2)
                            
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.body)
                                .fontWeight(.medium)
                                .weatherForegroundColor(for: weather)
                        }
                        .frame(width: 50)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}