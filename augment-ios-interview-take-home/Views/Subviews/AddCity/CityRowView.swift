//
//  CityRowView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

struct CityRowView: View {
    @State private var isAdding = false
    
    let city: City
    let onAdd: () async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.headline)
                
                Text(city.countryCode)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    isAdding = true
                    await onAdd()
                    isAdding = false
                }
            } label: {
                if isAdding {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .disabled(isAdding)
        }
        .padding(.vertical, 4)
    }
}
