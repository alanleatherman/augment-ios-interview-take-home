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
    
    private let predefinedCities = City.predefinedCities
    
    private var filteredCities: [City] {
        if searchText.isEmpty {
            return predefinedCities
        } else {
            return predefinedCities.filter { city in
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.countryCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                
                List(filteredCities) { city in
                    CityRowView(city: city) {
                        await addCity(city)
                    }
                }
                
                if filteredCities.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Cities Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching for a different city name")
                    )
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
            
            TextField("Search cities...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
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
