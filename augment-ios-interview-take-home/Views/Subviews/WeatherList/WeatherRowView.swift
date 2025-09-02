//
//  WeatherRowView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct WeatherRowView: View {
    let city: City
    let weather: Weather?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if city.isCurrentLocation {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(city.name)
                        .font(.headline)
                }
                
                if let weather = weather {
                    Text(weather.description.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let weather = weather {
                    Text(weather.temperatureFormatted)
                        .font(.largeTitle)
                        .fontWeight(.light)
                    
                    Text(weather.temperatureRangeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
