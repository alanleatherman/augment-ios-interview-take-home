//
//  MockWeatherInteractor.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import Foundation

@MainActor
class MockWeatherInteractor: WeatherInteractorProtocol {
    var addCityCalled = false
    var removeCityCalled = false
    var refreshWeatherCalled = false
    var lastAddedCity: City?
    var lastRemovedCity: City?
    
    func loadInitialData() async {
        // Mock implementation
    }
    
    func addCity(_ city: City) async {
        addCityCalled = true
        lastAddedCity = city
    }
    
    func removeCity(_ city: City) async {
        removeCityCalled = true
        lastRemovedCity = city
    }
    
    func refreshWeather(for city: City) async {
        refreshWeatherCalled = true
    }
    
    func refreshAllWeather() async {
        refreshWeatherCalled = true
    }
    
    func clearAllData() async {
        // Mock implementation
    }
    
    // Forecast methods
    func loadHourlyForecast(for city: City) async {
        // Mock implementation
    }
    
    func loadDailyForecast(for city: City) async {
        // Mock implementation
    }
    
    // Selected city management
    func updateSelectedCityIndex(_ index: Int) {
        // Mock implementation
    }
    
    // Home city management
    func markCurrentCityAsHome() {
        // Mock implementation
    }
    
    func clearHomeCity() {
        // Mock implementation
    }
    
    func isHomeCity(_ city: City) -> Bool {
        return false // Mock implementation
    }
    
    func handleLocationUpdate(for city: City) async {
        // Mock implementation
    }
}
