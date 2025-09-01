//
//  WeatherInteractor.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation

@MainActor
@Observable
final class WeatherInteractor: WeatherInteractorProtocol {
    private let repository: WeatherRepositoryProtocol
    private let appState: AppState
    
    // Observable state
    var isLoading = false
    var error: WeatherError?
    
    init(repository: WeatherRepositoryProtocol, appState: AppState) {
        self.repository = repository
        self.appState = appState
    }
    
    func loadInitialData() async {
        isLoading = true
        error = nil
        appState.weatherState.isLoading = true
        appState.weatherState.error = nil
        
        do {
            // Load cities from persistence
            let cities = try await repository.getAllCities()
            print("📍 Loaded \(cities.count) cities from persistence")
            appState.weatherState.cities = cities
            
            // If no cities exist, add predefined ones
            if cities.isEmpty {
                print("📍 No cities found, adding default cities...")
                for city in City.predefinedCities {
                    print("📍 Adding city: \(city.name)")
                    await addCity(city)
                }
                print("📍 Finished adding default cities. Total cities: \(appState.weatherState.cities.count)")
            } else {
                print("📍 Found existing cities, loading weather data...")
                // Load weather for existing cities
                await refreshAllWeather()
            }
            
            // Restore the last selected city index
            restoreSelectedCityIndex()
            
            appState.weatherState.lastRefresh = Date()
        } catch {
            print("❌ Error in loadInitialData: \(error)")
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
        
        isLoading = false
        appState.weatherState.isLoading = false
    }
    
    func addCity(_ city: City) async {
        do {
            print("📍 Adding city to repository: \(city.name)")
            // Add to repository
            try await repository.addCity(city)
            
            print("📍 Adding city to app state: \(city.name)")
            // Add to app state
            appState.weatherState.cities.append(city)
            
            print("📍 Loading weather for city: \(city.name)")
            // Load weather for the new city
            await refreshWeather(for: city)
            
        } catch {
            print("❌ Error adding city \(city.name): \(error)")
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    func removeCity(_ city: City) async {
        do {
            // Remove from repository
            try await repository.removeCity(city)
            
            // Remove from app state
            appState.weatherState.cities.removeAll { $0.id == city.id }
            appState.weatherState.weatherData.removeValue(forKey: city.id)
            appState.weatherState.hourlyForecasts.removeValue(forKey: city.id)
            appState.weatherState.dailyForecasts.removeValue(forKey: city.id)
            
        } catch {
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    func refreshWeather(for city: City) async {
        do {
            // Check cache first
            if let cachedWeather = repository.getCachedWeather(for: city.id) {
                appState.weatherState.weatherData[city.id] = cachedWeather
                return
            }
            
            // Fetch fresh data
            let weather = try await repository.getCurrentWeather(for: city)
            
            // Update app state
            appState.weatherState.weatherData[city.id] = weather
            
            // Cache the result
            repository.cacheWeather(weather)
            
        } catch {
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    func refreshAllWeather() async {
        isLoading = true
        error = nil
        appState.weatherState.isLoading = true
        appState.weatherState.error = nil
        
        // Get cities snapshot to avoid concurrent access
        let cities = appState.weatherState.cities
        
        // Refresh weather for all cities concurrently
        await withTaskGroup(of: Void.self) { group in
            for city in cities {
                group.addTask {
                    await self.refreshWeather(for: city)
                }
            }
        }
        
        appState.weatherState.lastRefresh = Date()
        isLoading = false
        appState.weatherState.isLoading = false
    }
    
    func clearAllData() async {
        do {
            try await repository.clearAllData()
            
            appState.weatherState.cities.removeAll()
            appState.weatherState.weatherData.removeAll()
            appState.weatherState.hourlyForecasts.removeAll()
            appState.weatherState.dailyForecasts.removeAll()
            appState.weatherState.lastRefresh = nil
            
        } catch {
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    // MARK: - Forecast Methods
    
    func loadHourlyForecast(for city: City) async {
        do {
            // Check cache first
            if let cachedForecast = repository.getCachedHourlyForecast(for: city.id) {
                appState.weatherState.hourlyForecasts[city.id] = cachedForecast
                return
            }
            
            // Fetch fresh data
            let forecast = try await repository.getHourlyForecast(for: city)
            
            // Update app state
            appState.weatherState.hourlyForecasts[city.id] = forecast
            
            // Cache the result
            repository.cacheHourlyForecast(forecast, for: city.id)
            
        } catch {
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    func loadDailyForecast(for city: City) async {
        do {
            // Check cache first
            if let cachedForecast = repository.getCachedDailyForecast(for: city.id) {
                appState.weatherState.dailyForecasts[city.id] = cachedForecast
                return
            }
            
            // Fetch fresh data
            let forecast = try await repository.getDailyForecast(for: city)
            
            // Update app state
            appState.weatherState.dailyForecasts[city.id] = forecast
            
            // Cache the result
            repository.cacheDailyForecast(forecast, for: city.id)
            
        } catch {
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        error = nil
        appState.weatherState.error = nil
    }
    
    nonisolated func hasWeatherData(for city: City) -> Bool {
        // This can be called from any thread since it's just checking
        return true // We'll implement this properly when we have real data
    }
    
    func retryLastFailedOperation() async {
        if error != nil {
            await refreshAllWeather()
        }
    }
    
    // MARK: - Selected City Management
    
    func updateSelectedCityIndex(_ index: Int) {
        guard index >= 0 && index < appState.weatherState.cities.count else { return }
        appState.weatherState.selectedCityIndex = index
        appState.appSettings.lastSelectedCityIndex = index
        print("📍 Updated selected city index to: \(index)")
    }
    
    private func restoreSelectedCityIndex() {
        let savedIndex = appState.appSettings.lastSelectedCityIndex
        let maxIndex = max(0, appState.weatherState.cities.count - 1)
        appState.weatherState.selectedCityIndex = min(savedIndex, maxIndex)
        print("📍 Restored selected city index: \(appState.weatherState.selectedCityIndex)")
    }
    
    // MARK: - Home City Management
    
    func markCurrentCityAsHome() {
        guard !appState.weatherState.cities.isEmpty else { return }
        let currentIndex = appState.weatherState.selectedCityIndex
        guard currentIndex < appState.weatherState.cities.count else { return }
        
        let currentCity = appState.weatherState.cities[currentIndex]
        appState.appSettings.homeCityId = currentCity.id
        print("📍 Marked city as home: \(currentCity.name)")
    }
    
    func clearHomeCity() {
        appState.appSettings.homeCityId = nil
        print("📍 Cleared home city")
    }
    
    func isHomeCity(_ city: City) -> Bool {
        return appState.appSettings.homeCityId == city.id
    }
}