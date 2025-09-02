//
//  DailyForecastCard.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct DailyForecastCard: View {
    let forecast: [DailyWeather]
    let weather: Weather?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .weatherSecondaryForegroundColor(for: weather)
                Text("5-DAY FORECAST")
                    .font(.caption)
                    .fontWeight(.medium)
                    .weatherSecondaryForegroundColor(for: weather)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(forecast.prefix(5).enumerated()), id: \.element.id) { index, day in
                    let isToday = Calendar.current.isDateInToday(day.date)
                    let displayMinTemp = isToday && weather != nil ? weather!.temperatureMin : day.temperatureMin
                    let displayMaxTemp = isToday && weather != nil ? weather!.temperatureMax : day.temperatureMax
                    let displayEmoji = isToday && weather != nil ? weather!.weatherConditionEmoji : day.weatherEmoji
                    
                    HStack {
                        Text(day.dayFormatted)
                            .font(.body)
                            .weatherForegroundColor(for: weather)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        Text(displayEmoji)
                            .font(.title3)
                            .frame(width: 30)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text("\(Int(displayMinTemp.rounded()))°")
                                .font(.body)
                                .weatherSecondaryForegroundColor(for: weather)
                                .frame(width: 30, alignment: .trailing)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 4)
                            
                            Text("\(Int(displayMaxTemp.rounded()))°")
                                .font(.body)
                                .weatherForegroundColor(for: weather)
                                .frame(width: 30, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if index != forecast.prefix(5).count - 1 {
                        Divider()
                            .background(weather.map { WeatherTheme.secondaryTextColor(for: $0) } ?? .white.opacity(0.3))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}