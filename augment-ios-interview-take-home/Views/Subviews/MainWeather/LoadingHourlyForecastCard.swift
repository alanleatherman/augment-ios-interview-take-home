//
//  LoadingHourlyForecastCard.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct LoadingHourlyForecastCard: View {
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
                    ForEach(0..<12, id: \.self) { _ in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                                .frame(width: 30, height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                                .frame(width: 25, height: 16)
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