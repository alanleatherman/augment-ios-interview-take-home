//
//  LocationPermissionDeniedView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import SwiftUI
import UIKit

struct LocationPermissionDeniedView: View {
    @Environment(\.appState) private var appState
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "location.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            // Title
            Text("Location Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Description
            VStack(spacing: 12) {
                Text("To show weather for your current location, please enable location access in Settings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Go to Settings > Privacy & Security > Location Services > Weather App")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                // Open Settings button
                Button {
                    openSettings()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 25))
                }
                
                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Continue Without Location")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func openSettings() {
        // Clear the error to provide better UX
        appState.weatherState.error = nil
        
        // Open Settings app
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        
        // Dismiss the view
        onDismiss()
    }
}

#Preview("Location Permission Denied") {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()
        
        LocationPermissionDeniedView {
            print("Dismissed")
        }
        .padding()
    }
}
