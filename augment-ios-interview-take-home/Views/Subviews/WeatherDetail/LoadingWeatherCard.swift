//
//  LoadingWeatherCard.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct LoadingWeatherCard: View {
    let cityName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(cityName)
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                
                Text("Loading weather...")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
            Divider()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WeatherDetailPlaceholder(title: "Feels Like")
                WeatherDetailPlaceholder(title: "Humidity")
                WeatherDetailPlaceholder(title: "Wind")
                WeatherDetailPlaceholder(title: "Pressure")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}
