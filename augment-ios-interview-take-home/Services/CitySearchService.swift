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
@Observable
class CitySearchService {
    var searchResults: [City] = []
    var isSearching = false
    var hasSearched = false
    
    private let geocoder = CLGeocoder()
    private nonisolated(unsafe) var searchTask: Task<Void, Never>?
    
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
            
            // Add debounce delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else {
                await MainActor.run {
                    isSearching = false
                }
                return 
            }
        
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]
            
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            var cities: [City] = []
            
            for item in response.mapItems.prefix(10) {
                if let placemark = item.placemark.location {
                    let cityName = item.placemark.locality ?? 
                                  item.placemark.subAdministrativeArea ?? 
                                  item.placemark.administrativeArea ?? 
                                  item.name ?? 
                                  "Unknown City"
                    
                    let countryCode = item.placemark.isoCountryCode ?? "US"
                    
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
            
            // Fallback to CLGeocoder
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
