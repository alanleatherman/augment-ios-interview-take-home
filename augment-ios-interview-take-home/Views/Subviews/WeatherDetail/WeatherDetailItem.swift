//
//  WeatherDetailItem.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct WeatherDetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
    }
}