//
//  WeatherInteractorTests.swift
//  augment-ios-interview-take-homeTests
//
//  Created by Alan Leatherman on 9/1/25.
//

import Testing
import Foundation
@testable import augment_ios_interview_take_home

@MainActor
struct WeatherInteractorTests {
    
    let appState: AppState
    let mockRepository: MockWeatherRepository
    let weatherInteractor: WeatherInteractor
    
    init() {
        appState = AppState()
        mockRepository = MockWeatherRepository()
        weatherInteractor = WeatherInteractor(repository: mockRepository, appState: appState)
    }
    
    // MARK: - Initial Data Loading Tests
    
    @Test("Load initial data with empty persistence adds default cities")
    func loadInitialDataWithEmptyPersistence() async throws {
        // Mock empty persistence
        mockRepository.mockCities = []
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify default cities were added
        #expect(!appState.weatherState.cities.isEmpty, "Should have default cities")
        #expect(appState.weatherState.cities.count == 6, "Should have 6 default cities")
        
        // Verify default cities are present
        let cityNames = appState.weatherState.cities.map { $0.name }
        #expect(cityNames.contains("Los Angeles"))
        #expect(cityNames.contains("San Francisco"))
        #expect(cityNames.contains("Austin"))
        #expect(cityNames.contains("Lisbon"))
        #expect(cityNames.contains("Auckland"))
        #expect(cityNames.contains("Rio de Janeiro"))
        
        // Verify loading state is cleared
        #expect(!appState.weatherState.isLoading)
        #expect(!weatherInteractor.isLoading)
    }
    
    @Test("Load initial data with existing cities preserves them and adds missing defaults")
    func loadInitialDataWithExistingCities() async throws {
        // Mock existing cities in persistence
        let existingCity = City(name: "New York", countryCode: "US", latitude: 40.7128, longitude: -74.0060)
        mockRepository.mockCities = [existingCity]
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify existing city is preserved and default cities are added
        #expect(appState.weatherState.cities.count >= 6, "Should have at least 6 cities")
        
        let cityNames = appState.weatherState.cities.map { $0.name }
        #expect(cityNames.contains("New York"), "Should preserve existing city")
        #expect(cityNames.contains("Los Angeles"), "Should add missing default cities")
    }
    
    @Test("Load initial data with persistence error falls back to default cities")
    func loadInitialDataWithPersistenceError() async throws {
        // Mock persistence error
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .persistenceFailure(NSError(domain: "Test", code: 1))
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify fallback to default cities
        #expect(!appState.weatherState.cities.isEmpty, "Should fallback to default cities")
        #expect(appState.weatherState.error != nil, "Should set error state")
        #expect(!appState.weatherState.isLoading, "Should clear loading state")
    }
    
    // MARK: - City Management Tests
    
    func testAddCity() async throws {
        let newCity = City(name: "Seattle", countryCode: "US", latitude: 47.6062, longitude: -122.3321)
        
        // Add city
        await weatherInteractor.addCity(newCity)
        
        // Verify city was added to app state
        XCTAssertTrue(appState.weatherState.cities.contains { $0.id == newCity.id })
        
        // Verify repository was called
        XCTAssertTrue(mockRepository.addCityCalled)
        XCTAssertEqual(mockRepository.lastAddedCity?.name, "Seattle")
        
        print("✅ Add city test passed")
    }
    
    func testAddCityWithError() async throws {
        let newCity = City(name: "Seattle", countryCode: "US", latitude: 47.6062, longitude: -122.3321)
        
        // Mock repository error
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .persistenceFailure(NSError(domain: "Test", code: 1))
        
        // Add city
        await weatherInteractor.addCity(newCity)
        
        // Verify error was set
        XCTAssertNotNil(appState.weatherState.error)
        XCTAssertNotNil(weatherInteractor.error)
        
        // Verify city was not added to app state
        XCTAssertFalse(appState.weatherState.cities.contains { $0.id == newCity.id })
        
        print("✅ Add city with error test passed")
    }
    
    func testRemoveCity() async throws {
        // Add a city first
        let cityToRemove = City(name: "Test City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        appState.weatherState.cities.append(cityToRemove)
        appState.weatherState.weatherData[cityToRemove.id] = Weather.sample
        
        // Remove city
        await weatherInteractor.removeCity(cityToRemove)
        
        // Verify city was removed from app state
        XCTAssertFalse(appState.weatherState.cities.contains { $0.id == cityToRemove.id })
        XCTAssertNil(appState.weatherState.weatherData[cityToRemove.id])
        
        // Verify repository was called
        XCTAssertTrue(mockRepository.removeCityCalled)
        
        print("✅ Remove city test passed")
    }
    
    // MARK: - Weather Data Tests
    
    func testRefreshWeatherWithCache() async throws {
        let testCity = City(name: "Test City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        let cachedWeather = Weather.sample
        
        // Mock cached weather
        mockRepository.mockCachedWeather[testCity.id] = cachedWeather
        
        // Refresh weather
        await weatherInteractor.refreshWeather(for: testCity)
        
        // Verify cached weather was used
        XCTAssertEqual(appState.weatherState.weatherData[testCity.id]?.id, cachedWeather.id)
        XCTAssertFalse(mockRepository.getCurrentWeatherCalled, "Should not call API when cache is available")
        
        print("✅ Refresh weather with cache test passed")
    }
    
    func testRefreshWeatherWithoutCache() async throws {
        let testCity = City(name: "Test City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        let freshWeather = Weather(
            id: UUID(),
            cityId: testCity.id,
            temperature: 75,
            feelsLike: 78,
            temperatureMin: 68,
            temperatureMax: 82,
            description: "Sunny",
            iconCode: "01d",
            humidity: 50,
            pressure: 1013,
            windSpeed: 10,
            windDirection: 180,
            visibility: 10000,
            lastUpdated: Date()
        )
        
        // Mock fresh weather from API
        mockRepository.mockWeatherResponse = freshWeather
        
        // Refresh weather
        await weatherInteractor.refreshWeather(for: testCity)
        
        // Verify fresh weather was fetched and cached
        XCTAssertEqual(appState.weatherState.weatherData[testCity.id]?.id, freshWeather.id)
        XCTAssertTrue(mockRepository.getCurrentWeatherCalled, "Should call API when no cache")
        XCTAssertTrue(mockRepository.cacheWeatherCalled, "Should cache the result")
        
        print("✅ Refresh weather without cache test passed")
    }
    
    func testRefreshWeatherWithError() async throws {
        let testCity = City(name: "Test City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        
        // Mock API error
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .networkFailure(URLError(.notConnectedToInternet))
        
        // Refresh weather
        await weatherInteractor.refreshWeather(for: testCity)
        
        // Verify error was set
        XCTAssertNotNil(appState.weatherState.error)
        XCTAssertNotNil(weatherInteractor.error)
        
        print("✅ Refresh weather with error test passed")
    }
    
    func testRefreshAllWeather() async throws {
        // Add multiple cities
        let cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0),
            City(name: "City 2", countryCode: "US", latitude: 41.0, longitude: -75.0),
            City(name: "City 3", countryCode: "US", latitude: 42.0, longitude: -76.0)
        ]
        appState.weatherState.cities = cities
        
        // Mock weather responses
        for city in cities {
            mockRepository.mockWeatherResponse = Weather(
                id: UUID(),
                cityId: city.id,
                temperature: 70,
                feelsLike: 72,
                temperatureMin: 65,
                temperatureMax: 75,
                description: "Clear",
                iconCode: "01d",
                humidity: 50,
                pressure: 1013,
                windSpeed: 5,
                windDirection: 180,
                visibility: 10000,
                lastUpdated: Date()
            )
        }
        
        // Refresh all weather
        await weatherInteractor.refreshAllWeather()
        
        // Verify all cities have weather data
        for city in cities {
            XCTAssertNotNil(appState.weatherState.weatherData[city.id], "Should have weather for \(city.name)")
        }
        
        // Verify loading states are cleared
        XCTAssertFalse(appState.weatherState.isLoading)
        XCTAssertFalse(weatherInteractor.isLoading)
        XCTAssertNotNil(appState.weatherState.lastRefresh)
        
        print("✅ Refresh all weather test passed")
    }
    
    // MARK: - Selected City Management Tests
    
    func testUpdateSelectedCityIndex() {
        // Add cities
        appState.weatherState.cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0),
            City(name: "City 2", countryCode: "US", latitude: 41.0, longitude: -75.0)
        ]
        
        // Update selected city index
        weatherInteractor.updateSelectedCityIndex(1)
        
        // Verify index was updated
        XCTAssertEqual(appState.weatherState.selectedCityIndex, 1)
        XCTAssertEqual(appState.appSettings.lastSelectedCityIndex, 1)
        
        print("✅ Update selected city index test passed")
    }
    
    func testUpdateSelectedCityIndexOutOfBounds() {
        // Add one city
        appState.weatherState.cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0)
        ]
        
        // Try to set invalid index
        weatherInteractor.updateSelectedCityIndex(5)
        
        // Verify index was not changed
        XCTAssertEqual(appState.weatherState.selectedCityIndex, 0)
        
        print("✅ Update selected city index out of bounds test passed")
    }
    
    // MARK: - Home City Management Tests
    
    func testMarkCurrentCityAsHome() {
        // Add cities
        let cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0),
            City(name: "City 2", countryCode: "US", latitude: 41.0, longitude: -75.0)
        ]
        appState.weatherState.cities = cities
        appState.weatherState.selectedCityIndex = 1
        
        // Mark current city as home
        weatherInteractor.markCurrentCityAsHome()
        
        // Verify home city was set
        XCTAssertEqual(appState.appSettings.homeCityId, cities[1].id)
        XCTAssertTrue(weatherInteractor.isHomeCity(cities[1]))
        XCTAssertFalse(weatherInteractor.isHomeCity(cities[0]))
        
        print("✅ Mark current city as home test passed")
    }
    
    func testClearHomeCity() {
        // Set a home city first
        let homeCity = City(name: "Home City", countryCode: "US", latitude: 40.0, longitude: -74.0)
        appState.appSettings.homeCityId = homeCity.id
        
        // Clear home city
        weatherInteractor.clearHomeCity()
        
        // Verify home city was cleared
        XCTAssertNil(appState.appSettings.homeCityId)
        XCTAssertFalse(weatherInteractor.isHomeCity(homeCity))
        
        print("✅ Clear home city test passed")
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Set errors
        weatherInteractor.error = .networkFailure(URLError(.notConnectedToInternet))
        appState.weatherState.error = .networkFailure(URLError(.notConnectedToInternet))
        
        // Clear errors
        weatherInteractor.clearError()
        
        // Verify errors were cleared
        XCTAssertNil(weatherInteractor.error)
        XCTAssertNil(appState.weatherState.error)
        
        print("✅ Clear error test passed")
    }
    
    func testRetryLastFailedOperation() async throws {
        // Set error state
        weatherInteractor.error = .networkFailure(URLError(.notConnectedToInternet))
        
        // Add a city to retry with
        appState.weatherState.cities = [City.sample]
        
        // Mock successful retry
        mockRepository.mockWeatherResponse = Weather.sample
        
        // Retry operation
        await weatherInteractor.retryLastFailedOperation()
        
        // Verify retry was attempted
        XCTAssertTrue(mockRepository.getCurrentWeatherCalled)
        XCTAssertFalse(appState.weatherState.isLoading)
        
        print("✅ Retry last failed operation test passed")
    }
    
    // MARK: - City Ordering Tests
    
    func testCityOrderingWithCurrentLocation() async throws {
        // Mock cities including current location
        let currentLocationCity = City(name: "Current Location", countryCode: "", latitude: 37.7749, longitude: -122.4194, isCurrentLocation: true)
        let regularCity = City(name: "Regular City", countryCode: "US", latitude: 40.7128, longitude: -74.0060)
        
        mockRepository.mockCities = [regularCity, currentLocationCity]
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify current location city is first
        XCTAssertTrue(appState.weatherState.cities.first?.isCurrentLocation == true, "Current location should be first")
        
        print("✅ City ordering with current location test passed")
    }
    
    func testCityOrderingWithHomeCity() async throws {
        // Mock cities
        let homeCity = City(name: "Home City", countryCode: "US", latitude: 40.7128, longitude: -74.0060)
        let otherCity = City(name: "Other City", countryCode: "US", latitude: 41.0, longitude: -75.0)
        
        mockRepository.mockCities = [otherCity, homeCity]
        appState.appSettings.homeCityId = homeCity.id
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify home city is first (after current location check)
        let firstNonCurrentLocationCity = appState.weatherState.cities.first { !$0.isCurrentLocation }
        XCTAssertEqual(firstNonCurrentLocationCity?.id, homeCity.id, "Home city should be first among non-current-location cities")
        
        print("✅ City ordering with home city test passed")
    }
    
    // MARK: - Forecast Tests
    
    func testLoadHourlyForecast() async throws {
        let testCity = City.sample
        let mockHourlyForecast = [
            HourlyWeather(time: Date(), temperature: 75, iconCode: "01d", description: "Clear"),
            HourlyWeather(time: Date().addingTimeInterval(3600), temperature: 73, iconCode: "01d", description: "Clear")
        ]
        
        // Mock forecast response
        mockRepository.mockHourlyForecast = mockHourlyForecast
        
        // Load hourly forecast
        await weatherInteractor.loadHourlyForecast(for: testCity)
        
        // Verify forecast was loaded
        XCTAssertEqual(appState.weatherState.hourlyForecasts[testCity.id]?.count, 2)
        XCTAssertTrue(mockRepository.getHourlyForecastCalled)
        
        print("✅ Load hourly forecast test passed")
    }
    
    func testLoadDailyForecast() async throws {
        let testCity = City.sample
        let mockDailyForecast = [
            DailyWeather(date: Date(), temperatureMin: 65, temperatureMax: 80, iconCode: "01d", description: "Clear", precipitationChance: 0.1),
            DailyWeather(date: Date().addingTimeInterval(86400), temperatureMin: 63, temperatureMax: 78, iconCode: "02d", description: "Partly Cloudy", precipitationChance: 0.2)
        ]
        
        // Mock forecast response
        mockRepository.mockDailyForecast = mockDailyForecast
        
        // Load daily forecast
        await weatherInteractor.loadDailyForecast(for: testCity)
        
        // Verify forecast was loaded
        XCTAssertEqual(appState.weatherState.dailyForecasts[testCity.id]?.count, 2)
        XCTAssertTrue(mockRepository.getDailyForecastCalled)
        
        print("✅ Load daily forecast test passed")
    }
    
    // MARK: - Persistence Tests
    
    func testSelectedCityIndexPersistence() {
        // Clear any existing UserDefaults for clean test
        UserDefaults.standard.removeObject(forKey: "lastSelectedCityIndex")
        
        // Add cities
        let cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0),
            City(name: "City 2", countryCode: "US", latitude: 41.0, longitude: -75.0),
            City(name: "City 3", countryCode: "US", latitude: 42.0, longitude: -76.0)
        ]
        appState.weatherState.cities = cities
        
        // Update selected city index to 2
        weatherInteractor.updateSelectedCityIndex(2)
        
        // Verify it was saved to UserDefaults
        let savedIndex = UserDefaults.standard.integer(forKey: "lastSelectedCityIndex")
        XCTAssertEqual(savedIndex, 2, "Selected city index should be persisted to UserDefaults")
        
        // Verify it was also updated in app state
        XCTAssertEqual(appState.weatherState.selectedCityIndex, 2)
        XCTAssertEqual(appState.appSettings.lastSelectedCityIndex, 2)
        
        print("✅ Selected city index persistence test passed")
    }
    
    func testSelectedCityIndexRestoration() async throws {
        // Set up UserDefaults with a saved index
        UserDefaults.standard.set(1, forKey: "lastSelectedCityIndex")
        
        // Mock cities
        let cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0),
            City(name: "City 2", countryCode: "US", latitude: 41.0, longitude: -75.0),
            City(name: "City 3", countryCode: "US", latitude: 42.0, longitude: -76.0)
        ]
        mockRepository.mockCities = cities
        
        // Load initial data (this should restore the saved index)
        await weatherInteractor.loadInitialData()
        
        // Verify the saved index was restored
        XCTAssertEqual(appState.weatherState.selectedCityIndex, 1, "Saved selected city index should be restored on app launch")
        
        print("✅ Selected city index restoration test passed")
    }
    
    func testSelectedCityIndexRestorationWithBounds() async throws {
        // Set up UserDefaults with an index that's out of bounds (5)
        UserDefaults.standard.set(5, forKey: "lastSelectedCityIndex")
        
        // Mock only 2 cities
        let cities = [
            City(name: "City 1", countryCode: "US", latitude: 40.0, longitude: -74.0),
            City(name: "City 2", countryCode: "US", latitude: 41.0, longitude: -75.0)
        ]
        mockRepository.mockCities = cities
        
        // Load initial data
        await weatherInteractor.loadInitialData()
        
        // Verify the index was clamped to valid bounds (should be 1, the max valid index)
        XCTAssertEqual(appState.weatherState.selectedCityIndex, 1, "Out of bounds saved index should be clamped to valid range")
        
        print("✅ Selected city index restoration with bounds test passed")
    }
}