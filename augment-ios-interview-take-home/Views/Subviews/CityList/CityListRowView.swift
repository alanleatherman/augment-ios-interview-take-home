//
//  CityListRowView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct CityListRowView: View {
    let city: City
    let weather: Weather?
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(city.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
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
                        .foregroundColor(.primary)
                    
                    Text(weather.temperatureRangeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(
            isSelected ? 
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.08))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            : nil
        )
    }
}