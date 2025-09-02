//
//  CityListView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import SwiftUI

struct CityListView: View {
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if appState.weatherState.isLoading && appState.weatherState.cities.isEmpty {
                ProgressView("Loading weather data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.weatherState.cities.isEmpty {
                EmptyStateView()
            } else {
                List {
                    ForEach(Array(appState.weatherState.citiesWithWeather.enumerated()), id: \.element.0.id) { index, cityWeather in
                        let (city, weather) = cityWeather
                        Button {
                            // Select this city and dismiss the sheet
                            interactors.weatherInteractor.updateSelectedCityIndex(index)
                            dismiss()
                        } label: {
                            CityListRowView(city: city, weather: weather, isSelected: index == appState.weatherState.selectedCityIndex)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCities)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func deleteCities(offsets: IndexSet) {
        for index in offsets {
            let city = appState.weatherState.cities[index]
            
            Task {
                await interactors.weatherInteractor.removeCity(city)
                
                // Adjust selectedCityIndex after removal
                let currentSelected = appState.weatherState.selectedCityIndex
                let newCityCount = appState.weatherState.cities.count
                
                if newCityCount > 0 {
                    if index < currentSelected {
                        interactors.weatherInteractor.updateSelectedCityIndex(currentSelected - 1)
                    } else if index == currentSelected {
                        // If deleting the selected city, select the previous one or 0
                        let newIndex = max(0, min(currentSelected, newCityCount - 1))
                        interactors.weatherInteractor.updateSelectedCityIndex(newIndex)
                    }
                }
            }
        }
    }
}



#Preview {
    NavigationStack {
        CityListView()
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
    }
    .inject(AppContainer.preview)
}
