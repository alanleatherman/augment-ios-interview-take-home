//
//  EmptyStateView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import SwiftUI
import UIKit

struct EmptyStateView: View {
    @Environment(\.appState) private var appState
    @Environment(\.container) private var container
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.9))
                
                VStack(spacing: 16) {
                    Text("Welcome to Weather")
                        .font(.largeTitle)
                        .fontWeight(.light)
                        .foregroundColor(.white)
                    
                    if appState.locationState.isRequestingLocation {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            
                            Text("Getting your location...")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Add cities to get started with weather forecasts")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                if !appState.locationState.isRequestingLocation {
                    VStack(spacing: 16) {
                        Button {
                            Task {
                                await container.addCurrentLocationCity()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if appState.locationState.isRequestingLocation {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.blue)
                                } else {
                                    Image(systemName: locationButtonIcon)
                                        .font(.title3)
                                }
                                
                                Text(locationButtonText)
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.white, in: RoundedRectangle(cornerRadius: 25))
                        }
                        .disabled(appState.locationState.isRequestingLocation)
                        .opacity(appState.locationState.isRequestingLocation ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: appState.locationState.isRequestingLocation)
                        
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button {
                            Task {
                                await addDefaultCities()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.title3)
                                Text("Add Cities Manually")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 25))
                        }
                    }
                }
                
                Spacer()
                
                if let error = appState.weatherState.error, error != .locationPermissionDenied {
                    VStack(spacing: 8) {
                        Text(error.localizedDescription)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        if let recoveryAction = error.recoveryAction {
                            Button(recoveryAction) {
                                handleErrorRecovery(error)
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .overlay(alignment: .center) {
            if case .locationPermissionDenied = appState.weatherState.error {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            appState.weatherState.error = nil
                        }
                    
                    LocationPermissionDeniedView {
                        appState.weatherState.error = nil
                    }
                    .padding(.horizontal, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.3), value: appState.weatherState.error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var locationButtonIcon: String {
        switch appState.locationState.authorizationStatus {
        case .notDetermined:
            return "location"
        case .denied, .restricted:
            return "location.slash"
        case .authorizedWhenInUse, .authorizedAlways:
            return "location.fill"
        @unknown default:
            return "location"
        }
    }
    
    private var locationButtonText: String {
        if appState.locationState.isRequestingLocation {
            return "Getting Location..."
        }
        
        switch appState.locationState.authorizationStatus {
        case .notDetermined:
            return "Use Current Location"
        case .denied, .restricted:
            return "Enable Location Access"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Add Current Location"
        @unknown default:
            return "Use Current Location"
        }
    }
    
    private func addDefaultCities() async {
        let defaultCities = [
            City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
            City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
            City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
            City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
            City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633)
        ]
        
        for city in defaultCities {
            await container.interactors.weatherInteractor.addCity(city)
        }
    }
    
    private func handleErrorRecovery(_ error: WeatherError) {
        switch error {
        case .locationPermissionDenied:
            appState.weatherState.error = nil
            
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        default:
            appState.weatherState.error = nil
            Task {
                await container.addCurrentLocationCity()
            }
        }
    }
}

#Preview("Empty State") {
    EmptyStateView()
        .inject(AppContainer.preview)
}

#Preview("Empty State - Loading") {
    let container = AppContainer.preview
    container.appState.locationState.isRequestingLocation = true
    
    return EmptyStateView()
        .inject(container)
}

#Preview("Empty State - Permission Denied") {
    let container = AppContainer.preview
    container.appState.locationState.authorizationStatus = .denied
    container.appState.weatherState.error = .locationPermissionDenied
    
    return EmptyStateView()
        .inject(container)
}
