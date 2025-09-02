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
                // Main swipeable weather pages
                TabView(selection: Binding(
                    get: { 
                        // Ensure the selected index is valid
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
                    // Ensure proper initialization when view appears
                    if !appState.weatherState.cities.isEmpty {
                        let currentIndex = appState.weatherState.selectedCityIndex
                        let maxIndex = appState.weatherState.cities.count - 1
                        if currentIndex > maxIndex {
                            interactors.weatherInteractor.updateSelectedCityIndex(0)
                        }
                    }
                }
                
                // Overlay controls
                VStack {
                    HStack {
                        // Location button
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
                        
                        // List button
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
                    .padding(.top, 60) // Enough space to clear Dynamic Island
                    
                    Spacer()
                    
                    // Custom page indicators with location arrow
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
                // Location loading indicator
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
                
                // Error banner
                if let error = appState.weatherState.error {
                    ErrorBannerView(error: error) {
                        appState.weatherState.error = nil
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.locationState.isRequestingLocation)
        }
        .overlay(alignment: .center) {
            // Location permission denied overlay
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
            // Start location monitoring when view appears if we have current location cities
            container.startLocationMonitoringIfNeeded()
        }
        .onDisappear {
            // Stop location monitoring when view disappears to save battery
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

struct WeatherPageView: View {
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    
    let cityIndex: Int
    
    private var city: City? {
        guard cityIndex >= 0 && cityIndex < appState.weatherState.cities.count else { return nil }
        return appState.weatherState.cities[cityIndex]
    }
    
    private var weather: Weather? {
        guard let city = city else { return nil }
        return appState.weatherState.weatherData[city.id]
    }
    
    private var hourlyForecast: [HourlyWeather] {
        guard let city = city else { return [] }
        return appState.weatherState.hourlyForecasts[city.id] ?? []
    }
    
    private var dailyForecast: [DailyWeather] {
        guard let city = city else { return [] }
        return appState.weatherState.dailyForecasts[city.id] ?? []
    }
    
    private var todayHighLowFormatted: String {
        // Use current weather API data for today's high/low (more accurate)
        return weather?.temperatureRangeFormatted ?? "H:--° L:--°"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with city name and current weather
                    VStack(spacing: 16) {
                        // Location indicator - only show for current location cities
                        if city?.isCurrentLocation == true {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .weatherSecondaryForegroundColor(for: weather)
                                Text("Current Location")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .weatherSecondaryForegroundColor(for: weather)
                            }
                            .padding(.top, 40) // Reduced from 80 to 40 (less than half)
                        } else {
                            // Add spacing for non-home cities
                            Spacer()
                                .frame(height: 40) // Reduced from 100 to 40 (less than half)
                        }
                        
                        // City name
                        Text(city?.name ?? "Loading...")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .weatherForegroundColor(for: weather)
                        
                        if let weather = weather {
                            // Current temperature
                            Text(weather.temperatureFormatted)
                                .font(.system(size: 96, weight: .thin))
                                .weatherForegroundColor(for: weather)
                                .offset(x: 12) // Slight offset to center better with degree symbol
                            
                            // Weather description
                            Text(weather.description.capitalized)
                                .font(.title2)
                                .weatherSecondaryForegroundColor(for: weather)
                            
                            // High/Low - use daily forecast for today if available, otherwise fall back to current weather
                            Text(todayHighLowFormatted)
                                .font(.title3)
                                .weatherSecondaryForegroundColor(for: weather)
                        } else {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(weather.map { WeatherTheme.textColor(for: $0) } ?? .white)
                                .padding(.vertical, 40)
                        }
                    }
                    .frame(minHeight: geometry.size.height * 0.4) // Reduced from 0.6 to 0.4 (less than half)
                    
                    // Weather details section
                    VStack(spacing: 20) {
                        if let weather = weather {
                            // Current conditions description
                            Text(weather.detailedDescription ?? "Current conditions will continue.")
                                .font(.body)
                                .weatherSecondaryForegroundColor(for: weather)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Hourly forecast
                        if !hourlyForecast.isEmpty {
                            HourlyForecastCard(forecast: hourlyForecast, weather: weather)
                        }
                        
                        // 10-day forecast
                        if !dailyForecast.isEmpty {
                            DailyForecastCard(forecast: dailyForecast, weather: weather)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Extended bottom padding to utilize black area
                }
            }
        }
        .weatherBackground(for: weather)
        .task {
            await loadWeatherData()
        }
        .refreshable {
            await refreshWeatherData()
        }
    }
    
    private func loadWeatherData() async {
        guard let city = city else { return }
        await interactors.weatherInteractor.loadHourlyForecast(for: city)
        await interactors.weatherInteractor.loadDailyForecast(for: city)
    }
    
    private func refreshWeatherData() async {
        guard let city = city else { return }
        await interactors.weatherInteractor.refreshWeather(for: city)
        await loadWeatherData()
    }
}

struct HourlyForecastCard: View {
    let forecast: [HourlyWeather]
    let weather: Weather?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .weatherSecondaryForegroundColor(for: weather)
                Text("HOURLY FORECAST")
                    .font(.caption)
                    .fontWeight(.medium)
                    .weatherSecondaryForegroundColor(for: weather)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecast.prefix(24)) { hour in
                        VStack(spacing: 8) {
                            Text(hour.timeFormatted)
                                .font(.caption)
                                .weatherSecondaryForegroundColor(for: weather)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                            
                            Text(hour.weatherEmoji)
                                .font(.title2)
                            
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.body)
                                .fontWeight(.medium)
                                .weatherForegroundColor(for: weather)
                        }
                        .frame(width: 50)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct DailyForecastCard: View {
    let forecast: [DailyWeather]
    let weather: Weather?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .weatherSecondaryForegroundColor(for: weather)
                Text("5-DAY FORECAST")
                    .font(.caption)
                    .fontWeight(.medium)
                    .weatherSecondaryForegroundColor(for: weather)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(Array(forecast.prefix(5).enumerated()), id: \.element.id) { index, day in
                    let isToday = Calendar.current.isDateInToday(day.date)
                    let displayMinTemp = isToday && weather != nil ? weather!.temperatureMin : day.temperatureMin
                    let displayMaxTemp = isToday && weather != nil ? weather!.temperatureMax : day.temperatureMax
                    let displayEmoji = isToday && weather != nil ? weather!.weatherConditionEmoji : day.weatherEmoji
                    
                    HStack {
                        Text(day.dayFormatted)
                            .font(.body)
                            .weatherForegroundColor(for: weather)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        Text(displayEmoji)
                            .font(.title3)
                            .frame(width: 30)
                        
                        Spacer()
                        
                        // Temperature range bar
                        HStack(spacing: 8) {
                            Text("\(Int(displayMinTemp.rounded()))°")
                                .font(.body)
                                .weatherSecondaryForegroundColor(for: weather)
                                .frame(width: 30, alignment: .trailing)
                            
                            // Temperature range indicator
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 4)
                            
                            Text("\(Int(displayMaxTemp.rounded()))°")
                                .font(.body)
                                .weatherForegroundColor(for: weather)
                                .frame(width: 30, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if index != forecast.prefix(5).count - 1 {
                        Divider()
                            .background(weather.map { WeatherTheme.secondaryTextColor(for: $0) } ?? .white.opacity(0.3))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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

// MARK: - Custom Page Indicator

struct CustomPageIndicator: View {
    let currentIndex: Int
    let totalPages: Int
    let cities: [City]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Group {
                    if index < cities.count && cities[index].isCurrentLocation {
                        // Show location arrow for current location city
                        Image(systemName: "location.fill")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(index == currentIndex ? .white : .white.opacity(0.5))
                    } else {
                        // Show regular dot for other cities
                        Circle()
                            .fill(index == currentIndex ? .white : .white.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}
