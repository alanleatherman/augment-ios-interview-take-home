//
//  LoadingDailyForecastView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct LoadingDailyForecastView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10-Day Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 24, height: 24)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 16)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if index < 9 {
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