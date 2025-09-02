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

struct CityListRowView: View {
    let city: City
    let weather: Weather?
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(city.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
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
                        .foregroundColor(.primary)
                    
                    Text(weather.temperatureRangeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(
            isSelected ? 
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.08))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            : nil
        )
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
