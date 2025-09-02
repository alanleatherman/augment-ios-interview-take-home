//
//  DailyForecastView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct DailyForecastView: View {
    let forecast: [DailyWeather]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10-Day Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(forecast.prefix(10)) { day in
                    HStack {
                        Text(day.dayFormatted)
                            .font(.body)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(day.weatherEmoji)
                            .font(.title3)
                        
                        Spacer()
                        
                        if day.precipitationChance > 0.1 {
                            Text("\(Int(day.precipitationChance * 100))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                        } else {
                            Spacer()
                                .frame(width: 40)
                        }
                        
                        Text("\(Int(day.temperatureMin.rounded()))°")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text("\(Int(day.temperatureMax.rounded()))°")
                            .font(.body)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if day.id != forecast.prefix(10).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}