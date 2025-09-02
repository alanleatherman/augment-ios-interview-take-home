//
//  MainWeatherView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/1/25.
//

import SwiftUI

struct MainWeatherView: View {
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    @Environment(\.container) private var container
    
    @State private var showingCityList = false
    
    var body: some View {
        ZStack {
            if appState.weatherState.cities.isEmpty {
                EmptyStateView()
            } else {
                TabView(selection: Binding(
                    get: { 
                        let index = appState.weatherState.selectedCityIndex
                        let maxIndex = max(0, appState.weatherState.cities.count - 1)
                        return min(index, maxIndex)
                    },
                    set: { newIndex in
                        interactors.weatherInteractor.updateSelectedCityIndex(newIndex)
                    }
                )) {
                    ForEach(Array(appState.weatherState.cities.enumerated()), id: \.element.id) { index, city in
                        WeatherPageView(cityIndex: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Hide default dots
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .onAppear {
                    if !appState.weatherState.cities.isEmpty {
                        let currentIndex = appState.weatherState.selectedCityIndex
                        let maxIndex = appState.weatherState.cities.count - 1
                        if currentIndex > maxIndex {
                            interactors.weatherInteractor.updateSelectedCityIndex(0)
                        }
                    }
                }
                
                VStack {
                    HStack {
                        Button {
                            Task {
                                await container.navigateToCurrentLocationCity()
                            }
                        } label: {
                            Group {
                                if appState.locationState.isRequestingLocation {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: locationButtonIcon)
                                        .font(.title2)
                                }
                            }
                            .foregroundColor(locationButtonColor)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                            .opacity(appState.locationState.isRequestingLocation ? 0.8 : 1.0)
                        }
                        .disabled(appState.locationState.isRequestingLocation)
                        .animation(.easeInOut(duration: 0.2), value: appState.locationState.isRequestingLocation)
                        
                        Spacer()
                        
                        Button {
                            showingCityList = true
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    CustomPageIndicator(
                        currentIndex: appState.weatherState.selectedCityIndex,
                        totalPages: appState.weatherState.cities.count,
                        cities: appState.weatherState.cities
                    )
                    .padding(.bottom, 50)
                }
            }
        }
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .sheet(isPresented: $showingCityList) {
            NavigationStack {
                CityListView()
                    .navigationTitle("Weather")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingCityList = false
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: AddCityView()) {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if appState.locationState.isRequestingLocation && !appState.weatherState.cities.isEmpty {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        
                        Text("Getting location...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 100) // Below the location button
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if let error = appState.weatherState.error {
                    ErrorBannerView(error: error) {
                        appState.weatherState.error = nil
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.locationState.isRequestingLocation)
        }
        .overlay(alignment: .center) {
            if case .locationPermissionDenied = appState.weatherState.error {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            appState.weatherState.error = nil
                        }
                    
                    LocationPermissionDeniedView {
                        appState.weatherState.error = nil
                    }
                    .padding(.horizontal, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.3), value: appState.weatherState.error)
            }
        }
        .onAppear {
            container.startLocationMonitoringIfNeeded()
        }
        .onDisappear {
            container.stopLocationMonitoring()
        }
    }
    

    
    // MARK: - Location Button State
    
    private var locationButtonIcon: String {
        let hasCurrentLocationCity = appState.weatherState.cities.contains { $0.isCurrentLocation }
        
        switch appState.locationState.authorizationStatus {
        case .notDetermined:
            return "location"
        case .denied, .restricted:
            return "location.slash"
        case .authorizedWhenInUse, .authorizedAlways:
            return hasCurrentLocationCity ? "location.fill" : "location"
        @unknown default:
            return "location"
        }
    }
    
    private var locationButtonColor: Color {
        let hasCurrentLocationCity = appState.weatherState.cities.contains { $0.isCurrentLocation }
        
        switch appState.locationState.authorizationStatus {
        case .denied, .restricted:
            return .red
        case .authorizedWhenInUse, .authorizedAlways:
            return hasCurrentLocationCity ? .blue : .primary
        default:
            return .primary
        }
    }
}





#Preview("Empty State") {
    MainWeatherView()
        .inject(AppContainer.preview)
}

#Preview("With Cities") {
    MainWeatherView()
        .inject(createPreviewContainer())
}

// MARK: - Preview Helper

private func createPreviewContainer() -> AppContainer {
    let appState = AppState()
    
    // Add sample cities with different weather conditions to test backgrounds
    appState.weatherState.cities = [
        City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
        City(name: "Austin", countryCode: "US", latitude: 30.2672, longitude: -97.7431),
        City(name: "London", countryCode: "GB", latitude: 51.5074, longitude: -0.1278, isCurrentLocation: true),
        City(name: "Tokyo", countryCode: "JP", latitude: 35.6762, longitude: 139.6503),
        City(name: "Denver", countryCode: "US", latitude: 39.7392, longitude: -104.9903),
        City(name: "Seattle", countryCode: "US", latitude: 47.6062, longitude: -122.3321)
    ]
    
    // Add realistic weather data for each location
    appState.weatherState.weatherData = [
        // San Francisco - Cool, foggy, typical SF weather
        appState.weatherState.cities[0].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[0].id,
            temperature: 62,
            feelsLike: 58,
            temperatureMin: 55,
            temperatureMax: 68,
            description: "Foggy",
            iconCode: "50d", // Fog - typical SF weather
            humidity: 85,
            pressure: 1013,
            windSpeed: 12.5,
            windDirection: 270,
            visibility: 3000,
            lastUpdated: Date()
        ),
        // Austin - Hot and sunny, typical Texas weather
        appState.weatherState.cities[1].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[1].id,
            temperature: 89,
            feelsLike: 95,
            temperatureMin: 78,
            temperatureMax: 94,
            description: "Sunny",
            iconCode: "01d", // Clear sky - hot Texas weather
            humidity: 45,
            pressure: 1015,
            windSpeed: 8.3,
            windDirection: 180,
            visibility: 15000,
            lastUpdated: Date()
        ),
        // London - Cool and rainy, typical UK weather
        appState.weatherState.cities[2].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[2].id,
            temperature: 58,
            feelsLike: 54,
            temperatureMin: 52,
            temperatureMax: 63,
            description: "Light rain",
            iconCode: "10d", // Rain - typical London weather
            humidity: 88,
            pressure: 1008,
            windSpeed: 15.2,
            windDirection: 270,
            visibility: 8000,
            lastUpdated: Date()
        ),
        // Tokyo - Mild and partly cloudy
        appState.weatherState.cities[3].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[3].id,
            temperature: 75,
            feelsLike: 78,
            temperatureMin: 68,
            temperatureMax: 81,
            description: "Partly cloudy",
            iconCode: "02d", // Few clouds - pleasant Tokyo weather
            humidity: 65,
            pressure: 1018,
            windSpeed: 6.8,
            windDirection: 90,
            visibility: 12000,
            lastUpdated: Date()
        ),
        // Denver - Cold with snow (mountain city, can get snow)
        appState.weatherState.cities[4].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[4].id,
            temperature: 28,
            feelsLike: 22,
            temperatureMin: 22,
            temperatureMax: 35,
            description: "Light snow",
            iconCode: "13d", // Snow - realistic for Denver in winter
            humidity: 85,
            pressure: 1005,
            windSpeed: 12.5,
            windDirection: 315,
            visibility: 5000,
            lastUpdated: Date()
        ),
        // Seattle - Cool and overcast, typical Pacific Northwest
        appState.weatherState.cities[5].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[5].id,
            temperature: 55,
            feelsLike: 52,
            temperatureMin: 48,
            temperatureMax: 61,
            description: "Overcast",
            iconCode: "04d", // Overcast clouds - typical Seattle weather
            humidity: 78,
            pressure: 1012,
            windSpeed: 9.2,
            windDirection: 240,
            visibility: 10000,
            lastUpdated: Date()
        )
    ]
    
    // Add sample hourly forecasts
    for city in appState.weatherState.cities {
        var hourlyForecast: [HourlyWeather] = []
        let currentWeather = appState.weatherState.weatherData[city.id]
        let baseIconCode = currentWeather?.iconCode ?? "01d"
        
        for i in 0..<24 {
            let time = Date().addingTimeInterval(TimeInterval(i * 3600))
            let baseTemp = currentWeather?.temperature ?? 70
            let tempVariation = Double.random(in: -5...5)
            
            hourlyForecast.append(HourlyWeather(
                id: UUID(),
                time: time,
                temperature: baseTemp + tempVariation,
                iconCode: baseIconCode, // Use same weather condition as current
                description: currentWeather?.description ?? "Partly cloudy"
            ))
        }
        appState.weatherState.hourlyForecasts[city.id] = hourlyForecast
    }
    
    // Add sample daily forecasts
    for city in appState.weatherState.cities {
        var dailyForecast: [DailyWeather] = []
        let currentWeather = appState.weatherState.weatherData[city.id]
        let baseIconCode = currentWeather?.iconCode ?? "01d"
        
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let baseTemp = currentWeather?.temperature ?? 70
            let tempVariation = Double.random(in: -10...10)
            
            dailyForecast.append(DailyWeather(
                id: UUID(),
                date: date,
                temperatureMin: baseTemp + tempVariation - 8,
                temperatureMax: baseTemp + tempVariation + 5,
                iconCode: baseIconCode, // Use same weather condition as current
                description: currentWeather?.description ?? "Partly cloudy",
                precipitationChance: baseIconCode.contains("10") || baseIconCode.contains("11") ? Double.random(in: 0.3...0.9) : Double.random(in: 0...0.3)
            ))
        }
        appState.weatherState.dailyForecasts[city.id] = dailyForecast
    }
    
    appState.weatherState.selectedCityIndex = 0
    
    return AppContainer(appState: appState, interactors: .stub)
}


