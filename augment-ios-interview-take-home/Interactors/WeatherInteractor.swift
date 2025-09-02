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
            
            // Check which repository type we're using for debugging
            let repositoryType = String(describing: type(of: repository))
            print("🌤️ Using repository: \(repositoryType)")
            
            // Always ensure default cities are present per spec requirements
            let requiredDefaultCities = [
                City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
                City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
                City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
                City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
                City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633)
            ]
            
            // Check which default cities are missing and add them
            var allCities = cities
            var addedDefaultCities = false
            
            for defaultCity in requiredDefaultCities {
                let cityExists = allCities.contains { existingCity in
                    existingCity.name == defaultCity.name && 
                    existingCity.countryCode == defaultCity.countryCode
                }
                
                if !cityExists {
                    print("📍 Adding missing default city: \(defaultCity.name)")
                    try await repository.addCity(defaultCity)
                    allCities.append(defaultCity)
                    addedDefaultCities = true
                }
            }
            
            if addedDefaultCities {
                print("📍 Added missing default cities. Total cities: \(allCities.count)")
            }
            
            // Sort cities to ensure favorite/last viewed city appears first
            allCities = sortCitiesWithFavoriteFirst(allCities)
            
            // Update app state with all cities (existing + any missing defaults)
            appState.weatherState.cities = allCities
            
            // Load weather for all cities
            await refreshAllWeather()
            
            // Restore the last selected city index
            restoreSelectedCityIndex()
            
            // Ensure the TabView starts with the correct index by triggering a state update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let currentIndex = self.appState.weatherState.selectedCityIndex
                self.updateSelectedCityIndex(currentIndex)
            }
            
            appState.weatherState.lastRefresh = Date()
            
        } catch {
            print("❌ Error in loadInitialData: \(error)")
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
            
            // If there's an error loading from persistence, still show default cities
            if appState.weatherState.cities.isEmpty {
                print("📍 Error loading from persistence, adding default cities as fallback...")
                let defaultCities = [
                    City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
                    City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
                    City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
                    City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
                    City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633)
                ]
                
                // Sort cities to ensure favorite city appears first
                let sortedDefaultCities = sortCitiesWithFavoriteFirst(defaultCities)
                
                // Add cities directly to app state as fallback
                appState.weatherState.cities = sortedDefaultCities
                
                // Try to load weather data for the default cities
                await refreshAllWeather()
            }
        }
        
        isLoading = false
        appState.weatherState.isLoading = false
    }
    
    func addCity(_ city: City) async {
        do {
            print("📍 Adding city to repository: \(city.name)")
            
            // If this is a current location city, remove any existing current location cities first
            if city.isCurrentLocation {
                let existingCurrentLocationCities = appState.weatherState.cities.filter { $0.isCurrentLocation }
                for existingCity in existingCurrentLocationCities {
                    print("📍 Removing existing current location city: \(existingCity.name)")
                    await removeCity(existingCity)
                }
            }
            
            // Add to repository
            try await repository.addCity(city)
            
            print("📍 Adding city to app state: \(city.name)")
            // Add to app state
            appState.weatherState.cities.append(city)
            
            // Re-sort cities to maintain proper ordering (favorite first)
            appState.weatherState.cities = sortCitiesWithFavoriteFirst(appState.weatherState.cities)
            
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
        print("🌤️ Refreshing weather for: \(city.name) at \(city.latitude), \(city.longitude)")
        
        // Try up to 3 times with exponential backoff
        var lastError: Error?
        for attempt in 1...3 {
            do {
                // Check cache first (only on first attempt)
                if attempt == 1, let cachedWeather = repository.getCachedWeather(for: city.id) {
                    print("🌤️ Using cached weather for: \(city.name)")
                    appState.weatherState.weatherData[city.id] = cachedWeather
                    return
                }
                
                if attempt > 1 {
                    print("🌤️ Retry attempt \(attempt) for: \(city.name)")
                    // Exponential backoff: 1s, 2s, 4s
                    try await Task.sleep(for: .seconds(Double(1 << (attempt - 1))))
                } else {
                    print("🌤️ No cached weather found, fetching fresh data for: \(city.name)")
                }
                
                // Fetch fresh data
                let weather = try await repository.getCurrentWeather(for: city)
                
                print("🌤️ Successfully fetched weather for: \(city.name) - \(weather.description)")
                
                // Update app state
                appState.weatherState.weatherData[city.id] = weather
                
                // Cache the result
                repository.cacheWeather(weather)
                
                // Clear any previous errors on success
                if self.error != nil {
                    self.error = nil
                    appState.weatherState.error = nil
                }
                
                return // Success, exit retry loop
                
            } catch {
                lastError = error
                print("❌ Attempt \(attempt) failed for \(city.name): \(error)")
                
                // Don't retry on certain errors
                if let weatherError = error as? WeatherError {
                    switch weatherError {
                    case .apiKeyInvalid, .cityNotFound:
                        // Don't retry these errors
                        break
                    default:
                        // Continue retrying for network errors
                        continue
                    }
                }
            }
        }
        
        // All retries failed
        if let lastError = lastError {
            print("❌ All retry attempts failed for \(city.name): \(lastError)")
            let weatherError = lastError as? WeatherError ?? .unknownError(lastError)
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
    
    // MARK: - Location Monitoring Integration
    
    func handleLocationUpdate(for city: City) async {
        print("📍 Handling location update for city: \(city.name) at \(city.latitude), \(city.longitude)")
        
        // Clear any cached weather for this city to force fresh data
        appState.weatherState.weatherData.removeValue(forKey: city.id)
        appState.weatherState.hourlyForecasts.removeValue(forKey: city.id)
        appState.weatherState.dailyForecasts.removeValue(forKey: city.id)
        
        // Clear repository cache for this city to force fresh API calls
        // We need to clear the entire cache since we don't have a method to clear just one city
        repository.clearCache()
        print("📍 Cleared all cached weather data to force fresh API calls")
        
        // Refresh weather for the updated location
        await refreshWeather(for: city)
        print("📍 Refreshed weather for updated location: \(city.name)")
        
        // Also reload forecast data
        await loadHourlyForecast(for: city)
        await loadDailyForecast(for: city)
        print("📍 Reloaded forecast data for updated location: \(city.name)")
    }
    
    func startLocationMonitoringIfNeeded() {
        // Check if we have a current location city and start monitoring
        let hasCurrentLocationCity = appState.weatherState.cities.contains { $0.isCurrentLocation }
        if hasCurrentLocationCity {
            // We'll need to access the location interactor through the container
            // This will be handled in AppContainer
        }
    }
    
    // MARK: - City Ordering
    
    private func sortCitiesWithFavoriteFirst(_ cities: [City]) -> [City] {
        var sortedCities = cities
        
        // Priority 1: Current location cities should always be first
        if let currentLocationIndex = sortedCities.firstIndex(where: { $0.isCurrentLocation }) {
            let currentLocationCity = sortedCities.remove(at: currentLocationIndex)
            sortedCities.insert(currentLocationCity, at: 0)
            print("📍 Moved current location city to front: \(currentLocationCity.name)")
            return sortedCities
        }
        
        // Priority 2: Check if we have a home city ID (last viewed city)
        if let homeCityId = appState.appSettings.homeCityId {
            // Find the home city and move it to the front
            if let homeCityIndex = sortedCities.firstIndex(where: { $0.id == homeCityId }) {
                let homeCity = sortedCities.remove(at: homeCityIndex)
                sortedCities.insert(homeCity, at: 0)
                print("📍 Moved home city to front: \(homeCity.name)")
                return sortedCities
            }
        }
        
        // Priority 3: If no home city is set, check if Rio de Janeiro (favorite city) exists and move it to front
        if let rioIndex = sortedCities.firstIndex(where: { $0.name == "Rio de Janeiro" && $0.countryCode == "BR" }) {
            let rioCity = sortedCities.remove(at: rioIndex)
            sortedCities.insert(rioCity, at: 0)
            print("📍 Moved favorite city (Rio de Janeiro) to front")
        }
        
        return sortedCities
    }
}