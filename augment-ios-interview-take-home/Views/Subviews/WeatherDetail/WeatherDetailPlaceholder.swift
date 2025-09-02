//
//  WeatherDetailPlaceholder.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct WeatherDetailPlaceholder: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 20)
                .frame(maxWidth: 60)
        }
    }
}