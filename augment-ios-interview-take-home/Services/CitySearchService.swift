//
//  CitySearchService.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import Foundation
import MapKit
import CoreLocation

@MainActor
class CitySearchService: ObservableObject {
    @Published var searchResults: [City] = []
    @Published var isSearching = false
    @Published var hasSearched = false
    
    private let geocoder = CLGeocoder()
    private var searchTask: Task<Void, Never>?
    
    func searchCities(query: String) async {
        // Cancel any existing search task
        searchTask?.cancel()
        
        searchTask = Task {
            guard !query.isEmpty else {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    hasSearched = false
                }
                return
            }
            
            // Loading state is already set in the view's onChange
            // hasSearched is already set to false in the view's onChange
            
            // Add debounce delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if task was cancelled during delay
            guard !Task.isCancelled else { 
                await MainActor.run {
                    isSearching = false
                }
                return 
            }
        
        do {
            // Use MKLocalSearch for better city search results
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            var cities: [City] = []
            
            for item in response.mapItems.prefix(10) { // Limit to 10 results
                if let placemark = item.placemark.location {
                    let cityName = item.placemark.locality ?? 
                                  item.placemark.subAdministrativeArea ?? 
                                  item.placemark.administrativeArea ?? 
                                  item.name ?? 
                                  "Unknown City"
                    
                    let countryCode = item.placemark.isoCountryCode ?? "US"
                    
                    // Avoid duplicates
                    if !cities.contains(where: { $0.name.lowercased() == cityName.lowercased() && $0.countryCode == countryCode }) {
                        let city = City(
                            name: cityName,
                            countryCode: countryCode,
                            latitude: placemark.coordinate.latitude,
                            longitude: placemark.coordinate.longitude
                        )
                        cities.append(city)
                    }
                }
            }
            
            // Fallback to CLGeocoder if MKLocalSearch doesn't find results
            if cities.isEmpty {
                let placemarks = try await geocoder.geocodeAddressString(query)
                
                for placemark in placemarks.prefix(5) {
                    if let location = placemark.location {
                        let cityName = placemark.locality ?? 
                                      placemark.subAdministrativeArea ?? 
                                      placemark.administrativeArea ?? 
                                      "Unknown City"
                        
                        let countryCode = placemark.isoCountryCode ?? "US"
                        
                        if !cities.contains(where: { $0.name.lowercased() == cityName.lowercased() && $0.countryCode == countryCode }) {
                            let city = City(
                                name: cityName,
                                countryCode: countryCode,
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude
                            )
                            cities.append(city)
                        }
                    }
                }
            }
            
            await MainActor.run {
                searchResults = cities
            }
            
            } catch {
                print("City search error: \(error)")
                await MainActor.run {
                    searchResults = []
                }
            }
            
            // Always reset loading state when search completes
            if !Task.isCancelled {
                await MainActor.run {
                    isSearching = false
                    hasSearched = true
                }
            }
        }
        
        await searchTask?.value
    }
    
    func clearResults() {
        searchTask?.cancel()
        searchResults = []
        isSearching = false
        hasSearched = false
    }
    
    deinit {
        searchTask?.cancel()
    }
}
