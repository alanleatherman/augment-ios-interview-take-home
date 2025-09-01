//
//  WeatherListView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import SwiftUI

struct WeatherListView: View {
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    
    var body: some View {
        Group {
            if appState.weatherState.isLoading && appState.weatherState.cities.isEmpty {
                ProgressView("Loading weather data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.weatherState.cities.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(appState.weatherState.citiesWithWeather, id: \.0.id) { city, weather in
                        NavigationLink(destination: WeatherDetailView(city: city)) {
                            WeatherRowView(city: city, weather: weather)
                        }
                    }
                    .onDelete(perform: deleteCities)
                }
            }
        }
        .overlay(alignment: .top) {
            if let error = appState.weatherState.error {
                ErrorBannerView(error: error) {
                    appState.weatherState.error = nil
                }
            }
        }
    }
    
    private func deleteCities(offsets: IndexSet) {
        for index in offsets {
            let city = appState.weatherState.cities[index]
            Task {
                await interactors.weatherInteractor.removeCity(city)
            }
        }
    }
}

struct WeatherRowView: View {
    let city: City
    let weather: Weather?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    // Show location icon only for GPS-detected current location
                    if city.isCurrentLocation {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(city.name)
                        .font(.headline)
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
                    
                    Text(weather.temperatureRangeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Cities Added")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add cities to see their weather")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: AddCityView()) {
                Label("Add City", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorBannerView: View {
    let error: WeatherError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.headline)
                
                Text(error.localizedDescription)
                    .font(.caption)
            }
            
            Spacer()
            
            Button("Dismiss", action: onDismiss)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        WeatherListView()
    }
    .inject(AppContainer.preview)
}