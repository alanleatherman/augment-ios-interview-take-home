//
//  LoadingDailyForecastCard.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct LoadingDailyForecastCard: View {
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
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.3))
                            .frame(width: 60, height: 16)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.3))
                            .frame(width: 30, height: 24)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                                .frame(width: 30, height: 16)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.white.opacity(0.3))
                                .frame(width: 60, height: 4)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.3))
                                .frame(width: 30, height: 16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if index != 4 {
                        Divider()
                            .background(.white.opacity(0.3))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}