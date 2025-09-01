//
//  StubInteractors.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

// MARK: - Stub Weather Interactor

final class StubWeatherInteractor: WeatherInteractorProtocol {
    
    func updateSelectedCityIndex(_ index: Int) {
        // No-op for stub
    }
    
    func loadInitialData() async {
        // No-op for stub
    }
    
    func addCity(_ city: City) async {
        // No-op for stub
    }
    
    func removeCity(_ city: City) async {
        // No-op for stub
    }
    
    func refreshWeather(for city: City) async {
        // No-op for stub
    }
    
    func refreshAllWeather() async {
        // No-op for stub
    }
    
    func clearAllData() async {
        // No-op for stub
    }
    
    func loadHourlyForecast(for city: City) async {
        // No-op for stub
    }
    
    func loadDailyForecast(for city: City) async {
        // No-op for stub
    }
    
    func markCurrentCityAsHome() {
        // No-op for stub
    }
    
    func clearHomeCity() {
        // No-op for stub
    }
    
    func isHomeCity(_ city: City) -> Bool {
        return false
    }
}

// MARK: - Stub Location Interactor

final class StubLocationInteractor: LocationInteractorProtocol {
    func requestLocationPermission() async {
        // No-op for stub
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        return CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
    
    func checkLocationPermission() -> Bool {
        return true
    }
}
