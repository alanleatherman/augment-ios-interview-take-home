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
            let cities = try await repository.getAllCities()
            print("📍 Loaded \(cities.count) cities from persistence")
            
            let repositoryType = String(describing: type(of: repository))
            print("🌤️ Using repository: \(repositoryType)")
            
            var allCities = cities
            
            if cities.isEmpty {
                print("📍 First launch detected - adding default cities")
                let defaultCities = [
                    City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
                    City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
                    City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
                    City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
                    City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633)
                ]
                
                for defaultCity in defaultCities {
                    try await repository.addCity(defaultCity)
                    allCities.append(defaultCity)
                }
                
                print("📍 Added \(defaultCities.count) default cities for first launch")
            } else {
                print("📍 Using existing \(cities.count) cities from persistence")
            }
            
            let sortedCities = sortCitiesWithFavoriteFirst(allCities)
            appState.weatherState.cities = sortedCities
            
            restoreSelectedCityIndex()
            
            await refreshAllWeather()
            
            appState.weatherState.lastRefresh = Date()
            
        } catch {
            print("❌ Error in loadInitialData: \(error)")
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
            
            if appState.weatherState.cities.isEmpty {
                print("📍 Error loading from persistence, adding default cities as fallback...")
                let defaultCities = [
                    City(name: "Los Angeles", countryCode: "US", latitude: 34.0522, longitude: -118.2437),
                    City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
                    City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
                    City(name: "Lisbon", countryCode: "PT", latitude: 38.7223, longitude: -9.1393),
                    City(name: "Auckland", countryCode: "NZ", latitude: -36.8485, longitude: 174.7633)
                ]
                
                let sortedDefaultCities = sortCitiesWithFavoriteFirst(defaultCities)
                appState.weatherState.cities = sortedDefaultCities
        
                await refreshAllWeather()
            }
        }
        
        isLoading = false
        appState.weatherState.isLoading = false
    }
    
    func addCity(_ city: City) async {
        do {
            print("📍 Adding city to repository: \(city.name)")
            
            if city.isCurrentLocation {
                let existingCurrentLocationCities = appState.weatherState.cities.filter { $0.isCurrentLocation }
                for existingCity in existingCurrentLocationCities {
                    print("📍 Removing existing current location city: \(existingCity.name)")
                    await removeCity(existingCity)
                }
            }
            
            try await repository.addCity(city)
            
            print("📍 Adding city to app state: \(city.name)")
            
            appState.weatherState.cities.append(city)
            appState.weatherState.cities = sortCitiesWithFavoriteFirst(appState.weatherState.cities)
            
            print("📍 Loading weather for city: \(city.name)")
            
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
            try await repository.removeCity(city)
            
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
                
                let weather = try await repository.getCurrentWeather(for: city)
                print("🌤️ Successfully fetched weather for: \(city.name) - \(weather.description)")
                
                appState.weatherState.weatherData[city.id] = weather
                repository.cacheWeather(weather)
                
                if self.error != nil {
                    self.error = nil
                    appState.weatherState.error = nil
                }
                
                return
            } catch {
                lastError = error
                
                if let weatherError = error as? WeatherError,
                   case .networkFailure(let underlyingError) = weatherError,
                   let urlError = underlyingError as? URLError,
                   urlError.code == .cancelled {
                    print("⚠️ Request cancelled for \(city.name) (attempt \(attempt)) - this is normal during rapid UI updates")
                    return
                }
                
                print("❌ Attempt \(attempt) failed for \(city.name): \(error)")
                
                if let weatherError = error as? WeatherError {
                    switch weatherError {
                    case .apiKeyInvalid, .cityNotFound:
                        break
                    case .networkFailure(let underlyingError):
                        if let urlError = underlyingError as? URLError, urlError.code == .cancelled {
                            return
                        }
                        continue
                    default:
                        continue
                    }
                }
            }
        }
        
        // All retries failed - but only show error if it wasn't a cancellation
        if let lastError = lastError {
            if let weatherError = lastError as? WeatherError,
               case .networkFailure(let underlyingError) = weatherError,
               let urlError = underlyingError as? URLError,
               urlError.code == .cancelled {
                print("⚠️ Final attempt was cancelled for \(city.name) - not showing error banner")
                return
            }
            
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
        
        let cities = appState.weatherState.cities
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
            if let cachedForecast = repository.getCachedHourlyForecast(for: city.id) {
                print("📊 Using cached hourly forecast for \(city.name) (\(cachedForecast.count) hours)")
                appState.weatherState.hourlyForecasts[city.id] = cachedForecast
                return
            }
            
            print("📊 Fetching fresh hourly forecast for \(city.name)")
            
            let forecast = try await repository.getHourlyForecast(for: city)
            appState.weatherState.hourlyForecasts[city.id] = forecast
            
            repository.cacheHourlyForecast(forecast, for: city.id)
            print("📊 Cached hourly forecast for \(city.name) (\(forecast.count) hours)")
        } catch {
            if let weatherError = error as? WeatherError,
               case .networkFailure(let underlyingError) = weatherError,
               let urlError = underlyingError as? URLError,
               urlError.code == .cancelled {
                print("⚠️ Hourly forecast request cancelled for \(city.name) - this is normal")
                return
            }
            
            let weatherError = error as? WeatherError ?? .unknownError(error)
            self.error = weatherError
            appState.weatherState.error = weatherError
        }
    }
    
    func loadDailyForecast(for city: City) async {
        do {
            if let cachedForecast = repository.getCachedDailyForecast(for: city.id) {
                print("📊 Using cached daily forecast for \(city.name) (\(cachedForecast.count) days)")
                appState.weatherState.dailyForecasts[city.id] = cachedForecast
                return
            }
            
            print("📊 Fetching fresh daily forecast for \(city.name)")

            let forecast = try await repository.getDailyForecast(for: city)
            appState.weatherState.dailyForecasts[city.id] = forecast
            repository.cacheDailyForecast(forecast, for: city.id)
            
            print("📊 Cached daily forecast for \(city.name) (\(forecast.count) days)")
        } catch {
            if let weatherError = error as? WeatherError,
               case .networkFailure(let underlyingError) = weatherError,
               let urlError = underlyingError as? URLError,
               urlError.code == .cancelled {
                print("⚠️ Daily forecast request cancelled for \(city.name) - this is normal")
                return
            }
            
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
        let cityCount = appState.weatherState.cities.count
        
        guard cityCount > 0 else {
            appState.weatherState.selectedCityIndex = 0
            return
        }
        
        let savedIndex = appState.appSettings.lastSelectedCityIndex
        let validIndex = max(0, min(savedIndex, cityCount - 1))
        
        appState.weatherState.selectedCityIndex = validIndex
        
        print("📍 Restored selected city index: \(validIndex) (saved: \(savedIndex), cities: \(cityCount))")
        
        if validIndex != savedIndex {
            appState.appSettings.lastSelectedCityIndex = validIndex
            print("📍 Corrected and saved selected city index: \(validIndex)")
        }
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
        
        appState.weatherState.weatherData.removeValue(forKey: city.id)
        appState.weatherState.hourlyForecasts.removeValue(forKey: city.id)
        appState.weatherState.dailyForecasts.removeValue(forKey: city.id)
        
        repository.clearCache()
        print("📍 Cleared all cached weather data to force fresh API calls")
        
        await refreshWeather(for: city)
        print("📍 Refreshed weather for updated location: \(city.name)")
        
        await loadHourlyForecast(for: city)
        await loadDailyForecast(for: city)
        print("📍 Reloaded forecast data for updated location: \(city.name)")
    }
    
    func startLocationMonitoringIfNeeded() {
        let hasCurrentLocationCity = appState.weatherState.cities.contains { $0.isCurrentLocation }
        if hasCurrentLocationCity {
            // We'll need to access the location interactor through the container
            // This will be handled in AppContainer
        }
    }
    
    // MARK: - City Ordering
    
    private func sortCitiesWithFavoriteFirst(_ cities: [City]) -> [City] {
        var sortedCities = cities
        
        // Priority 1: Current location city goes first
        if let currentLocationIndex = sortedCities.firstIndex(where: { $0.isCurrentLocation }) {
            let currentLocationCity = sortedCities.remove(at: currentLocationIndex)
            sortedCities.insert(currentLocationCity, at: 0)
            print("📍 Moved current location city to front: \(currentLocationCity.name)")
            return sortedCities
        }
        
        // Priority 2: Home city goes first (if no current location city)
        if let homeCityId = appState.appSettings.homeCityId {
            if let homeCityIndex = sortedCities.firstIndex(where: { $0.id == homeCityId }) {
                let homeCity = sortedCities.remove(at: homeCityIndex)
                sortedCities.insert(homeCity, at: 0)
                print("📍 Moved home city to front: \(homeCity.name)")
                return sortedCities
            }
        }
        
        return sortedCities
    }
}
