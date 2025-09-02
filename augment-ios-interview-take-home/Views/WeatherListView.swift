//
//  WeatherListView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import SwiftUI
import UIKit

struct WeatherListView: View {
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    
    var body: some View {
        Group {
            if appState.weatherState.isLoading && appState.weatherState.cities.isEmpty {
                ProgressView("Loading weather data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.weatherState.cities.isEmpty {
                // This should rarely happen now since we always load default cities
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
                .refreshable {
                    await interactors.weatherInteractor.refreshAllWeather()
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



#Preview {
    NavigationStack {
        WeatherListView()
    }
    .inject(AppContainer.preview)
}