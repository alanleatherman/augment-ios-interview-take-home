//
//  City.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftData

@Model
final class City {
    var id: UUID
    var name: String
    var countryCode: String
    var latitude: Double
    var longitude: Double
    var isCurrentLocation: Bool
    var dateAdded: Date
    
    init(id: UUID = UUID(), 
         name: String, 
         countryCode: String, 
         latitude: Double, 
         longitude: Double, 
         isCurrentLocation: Bool = false) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.isCurrentLocation = isCurrentLocation
        self.dateAdded = Date()
    }
}

// MARK: - Predefined Cities

extension City {
    static let predefinedCities = [
        City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
        City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
        City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
        City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
        City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633),
        City(name: "New York", countryCode: "US", latitude: 40.7128, longitude: -74.0060)
    ]
    
    static let sample = City(
        name: "San Francisco",
        countryCode: "US",
        latitude: 37.7749,
        longitude: -122.4194
    )
}

// MARK: - Identifiable & Equatable

extension City: Identifiable, Equatable {
    static func == (lhs: City, rhs: City) -> Bool {
        lhs.id == rhs.id
    }
}