//
//  CustomPageIndicator.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct CustomPageIndicator: View {
    let currentIndex: Int
    let totalPages: Int
    let cities: [City]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Group {
                    if index < cities.count && cities[index].isCurrentLocation {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(index == currentIndex ? .white : .white.opacity(0.5))
                    } else {
                        Circle()
                            .fill(index == currentIndex ? .white : .white.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}
