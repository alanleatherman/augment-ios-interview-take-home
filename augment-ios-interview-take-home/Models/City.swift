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
        // US Cities
        City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
        City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
        City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
        City(name: "New York", countryCode: "US", latitude: 40.7128, longitude: -74.0060),
        City(name: "Chicago", countryCode: "US", latitude: 41.8781, longitude: -87.6298),
        City(name: "Miami", countryCode: "US", latitude: 25.7617, longitude: -80.1918),
        City(name: "Seattle", countryCode: "US", latitude: 47.6062, longitude: -122.3321),
        City(name: "Denver", countryCode: "US", latitude: 39.7392, longitude: -104.9903),
        
        // International Cities
        City(name: "London", countryCode: "GB", latitude: 51.5074, longitude: -0.1278),
        City(name: "Paris", countryCode: "FR", latitude: 48.8566, longitude: 2.3522),
        City(name: "Tokyo", countryCode: "JP", latitude: 35.6762, longitude: 139.6503),
        City(name: "Sydney", countryCode: "AU", latitude: -33.8688, longitude: 151.2093),
        City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
        City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633),
        City(name: "Berlin", countryCode: "DE", latitude: 52.5200, longitude: 13.4050),
        City(name: "Rome", countryCode: "IT", latitude: 41.9028, longitude: 12.4964),
        
        // South American Cities (including Rio!)
        City(name: "Rio de Janeiro", countryCode: "BR", latitude: -22.9068, longitude: -43.1729),
        City(name: "São Paulo", countryCode: "BR", latitude: -23.5505, longitude: -46.6333),
        City(name: "Buenos Aires", countryCode: "AR", latitude: -34.6118, longitude: -58.3960),
        City(name: "Lima", countryCode: "PE", latitude: -12.0464, longitude: -77.0428),
        
        // Asian Cities
        City(name: "Singapore", countryCode: "SG", latitude: 1.3521, longitude: 103.8198),
        City(name: "Hong Kong", countryCode: "HK", latitude: 22.3193, longitude: 114.1694),
        City(name: "Seoul", countryCode: "KR", latitude: 37.5665, longitude: 126.9780),
        City(name: "Bangkok", countryCode: "TH", latitude: 13.7563, longitude: 100.5018)
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