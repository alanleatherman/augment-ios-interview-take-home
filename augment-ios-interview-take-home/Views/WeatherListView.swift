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

#Preview {
    NavigationStack {
        WeatherListView()
    }
    .inject(AppContainer.preview)
}
