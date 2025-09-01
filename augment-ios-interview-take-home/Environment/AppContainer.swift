//
//  AppContainer.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftUI
import CoreLocation

struct AppContainer {
    let appState: AppState
    let interactors: Interactors
    
    init(appState: AppState = AppState(), interactors: Interactors = .stub) {
        self.appState = appState
        self.interactors = interactors
    }
    
    struct Interactors {
        let weatherInteractor: WeatherInteractorProtocol
        let locationInteractor: LocationInteractorProtocol
        
        static var stub: Self {
            .init(
                weatherInteractor: StubWeatherInteractor(),
                locationInteractor: StubLocationInteractor()
            )
        }
    }
    
    @MainActor
    static var preview: AppContainer {
        let appState = AppState()
        let weatherInteractor = WeatherInteractor(
            repository: WeatherPreviewRepository(),
            appState: appState
        )
        let locationInteractor = LocationInteractor(
            repository: LocationPreviewRepository(),
            appState: appState
        )
        
        let interactors = AppContainer.Interactors(
            weatherInteractor: weatherInteractor,
            locationInteractor: locationInteractor
        )
        
        return AppContainer(appState: appState, interactors: interactors)
    }
    
    static var stub: AppContainer {
        let appState = AppState()
        return AppContainer(appState: appState, interactors: .stub)
    }
    
    // MARK: - Coordinated Operations
    
    func refreshAllWeather() async {
        await interactors.weatherInteractor.refreshAllWeather()
    }
    
    func clearAllData() async {
        await interactors.weatherInteractor.clearAllData()
        await MainActor.run {
            appState.weatherState.cities.removeAll()
            appState.weatherState.weatherData.removeAll()
            appState.weatherState.hourlyForecasts.removeAll()
            appState.weatherState.dailyForecasts.removeAll()
        }
    }
    
    func addCurrentLocationCity() async {
        guard let location = appState.locationState.currentLocation else { return }
        
        let currentLocationCity = City(
            name: "Current Location",
            countryCode: "",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            isCurrentLocation: true
        )
        
        await interactors.weatherInteractor.addCity(currentLocationCity)
    }
}

// MARK: - Environment Keys

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue = AppContainer(appState: AppState(), interactors: .stub)
}

private struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState()
}

private struct InteractorsKey: EnvironmentKey {
    static let defaultValue = AppContainer.Interactors.stub
}

// MARK: - Environment Values Extensions

extension EnvironmentValues {
    var container: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
    
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
    
    var interactors: AppContainer.Interactors {
        get { self[InteractorsKey.self] }
        set { self[InteractorsKey.self] = newValue }
    }
}

// MARK: - View Extension for Dependency Injection

extension View {
    func inject(_ container: AppContainer) -> some View {
        self.environment(\.container, container)
            .environment(\.appState, container.appState)
            .environment(\.interactors, container.interactors)
    }
}