//
//  AddCityView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import SwiftUI

struct AddCityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.interactors) private var interactors
    
    @State private var searchText = ""
    @State private var isLoading = false
    @StateObject private var citySearchService = CitySearchService()
    
    private let predefinedCities = City.predefinedCities
    
    private var displayedCities: [City] {
        if searchText.isEmpty {
            return predefinedCities
        } else {
            let filteredPredefined = predefinedCities.filter { city in
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.countryCode.localizedCaseInsensitiveContains(searchText)
            }
            
            let dynamicResults = citySearchService.searchResults.filter { searchResult in
                !filteredPredefined.contains { predefined in
                    predefined.name.lowercased() == searchResult.name.lowercased() &&
                    predefined.countryCode.lowercased() == searchResult.countryCode.lowercased()
                }
            }
            
            return filteredPredefined + dynamicResults
        }
    }
    
    private var isSearching: Bool {
        citySearchService.isSearching
    }
    
    private var shouldShowEmptyState: Bool {
        !searchText.isEmpty && displayedCities.isEmpty && !isSearching && citySearchService.hasSearched
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        // Clear previous results immediately when text changes
                        if newValue.isEmpty {
                            citySearchService.clearResults()
                        } else {
                            // Set searching state immediately and clear hasSearched to prevent premature empty state
                            citySearchService.isSearching = true
                            citySearchService.hasSearched = false
                        }
                        
                        Task {
                            await citySearchService.searchCities(query: newValue)
                        }
                    }
                
                if isSearching {
                    // Loading state
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Searching cities...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if shouldShowEmptyState {
                    // Empty state - takes full remaining space
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No Cities Found")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Try searching for a different city name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List of cities
                    List {
                        if !searchText.isEmpty && !displayedCities.isEmpty {
                            Section {
                                ForEach(displayedCities) { city in
                                    CityRowView(city: city) {
                                        await addCity(city)
                                    }
                                }
                            } header: {
                                Text(searchText.isEmpty ? "Popular Cities" : "Search Results")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(displayedCities) { city in
                                CityRowView(city: city) {
                                    await addCity(city)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isLoading)
        }
    }
    
    private func addCity(_ city: City) async {
        isLoading = true
        
        await interactors.weatherInteractor.addCity(city)
        
        isLoading = false
        dismiss()
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search cities", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

struct CityRowView: View {
    let city: City
    let onAdd: () async -> Void
    @State private var isAdding = false
    
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

#Preview {
    AddCityView()
        .inject(AppContainer.stub)
}
