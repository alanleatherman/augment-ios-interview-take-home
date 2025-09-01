//
//  MainWeatherView.swift
//  augment-ios-interview-take-home
//
//  Created by Kiro on 9/1/25.
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
                    get: { appState.weatherState.selectedCityIndex },
                    set: { newIndex in
                        interactors.weatherInteractor.updateSelectedCityIndex(newIndex)
                    }
                )) {
                    ForEach(Array(appState.weatherState.cities.enumerated()), id: \.element.id) { index, city in
                        WeatherPageView(city: city)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                // Overlay controls
                VStack {
                    HStack {
                        // Location button
                        Button {
                            Task {
                                await addCurrentLocationCity()
                            }
                        } label: {
                            Image(systemName: "location")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        
                        Spacer()
                        
                        // List button
                        Button {
                            showingCityList = true
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60) // Enough space to clear Dynamic Island
                    
                    Spacer()
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
            if let error = appState.weatherState.error {
                ErrorBannerView(error: error) {
                    appState.weatherState.error = nil
                }
            }
        }
    }
    
    private func addCurrentLocationCity() async {
        await container.addCurrentLocationCity()
    }
}

struct WeatherPageView: View {
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    
    let city: City
    
    private var weather: Weather? {
        appState.weatherState.weatherData[city.id]
    }
    
    private var hourlyForecast: [HourlyWeather] {
        appState.weatherState.hourlyForecasts[city.id] ?? []
    }
    
    private var dailyForecast: [DailyWeather] {
        appState.weatherState.dailyForecasts[city.id] ?? []
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with city name and current weather
                    VStack(spacing: 16) {
                        // Location indicator - only show for current location cities
                        if city.isCurrentLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Current Location")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 40) // Reduced from 80 to 40 (less than half)
                        } else {
                            // Add spacing for non-home cities
                            Spacer()
                                .frame(height: 40) // Reduced from 100 to 40 (less than half)
                        }
                        
                        // City name
                        Text(city.name)
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .foregroundColor(.white)
                        
                        if let weather = weather {
                            // Current temperature
                            Text(weather.temperatureFormatted)
                                .font(.system(size: 96, weight: .thin))
                                .foregroundColor(.white)
                            
                            // Weather description
                            Text(weather.description.capitalized)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                            
                            // High/Low
                            Text(weather.temperatureRangeFormatted)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
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
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Hourly forecast
                        if !hourlyForecast.isEmpty {
                            HourlyForecastCard(forecast: hourlyForecast)
                        }
                        
                        // 10-day forecast
                        if !dailyForecast.isEmpty {
                            DailyForecastCard(forecast: dailyForecast)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Extended bottom padding to utilize black area
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.blue.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all) // Extends to all edges including safe area
        )
        .task {
            await loadWeatherData()
        }
        .refreshable {
            await refreshWeatherData()
        }
    }
    
    private func loadWeatherData() async {
        await interactors.weatherInteractor.loadHourlyForecast(for: city)
        await interactors.weatherInteractor.loadDailyForecast(for: city)
    }
    
    private func refreshWeatherData() async {
        await interactors.weatherInteractor.refreshWeather(for: city)
        await loadWeatherData()
    }
}

struct HourlyForecastCard: View {
    let forecast: [HourlyWeather]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.white.opacity(0.8))
                Text("HOURLY FORECAST")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecast.prefix(24)) { hour in
                        VStack(spacing: 8) {
                            Text(hour.timeFormatted)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(hour.weatherEmoji)
                                .font(.title2)
                            
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.8))
                Text("10-DAY FORECAST")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(forecast.prefix(10)) { day in
                    HStack {
                        Text(day.dayFormatted)
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(width: 60, alignment: .leading)
                        
                        Text(day.weatherEmoji)
                            .font(.title3)
                        
                        Spacer()
                        
                        // Temperature range bar
                        HStack(spacing: 8) {
                            Text("\(Int(day.temperatureMin.rounded()))°")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.6))
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
                            
                            Text("\(Int(day.temperatureMax.rounded()))°")
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(width: 30, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if day.id != forecast.prefix(10).last?.id {
                        Divider()
                            .background(.white.opacity(0.3))
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
    
    // Add sample cities
    appState.weatherState.cities = [
        City(name: "San Francisco", countryCode: "US", latitude: 37.7749, longitude: -122.4194),
        City(name: "New York", countryCode: "US", latitude: 40.7128, longitude: -74.0060),
        City(name: "London", countryCode: "GB", latitude: 51.5074, longitude: -0.1278, isCurrentLocation: true),
        City(name: "Tokyo", countryCode: "JP", latitude: 35.6762, longitude: 139.6503)
    ]
    
    // Add sample weather data
    appState.weatherState.weatherData = [
        appState.weatherState.cities[0].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[0].id,
            temperature: 72,
            feelsLike: 75,
            temperatureMin: 65,
            temperatureMax: 78,
            description: "Partly cloudy",
            iconCode: "02d",
            humidity: 65,
            pressure: 1013,
            windSpeed: 8.5,
            windDirection: 180,
            visibility: 10000,
            lastUpdated: Date()
        ),
        appState.weatherState.cities[1].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[1].id,
            temperature: 68,
            feelsLike: 65,
            temperatureMin: 62,
            temperatureMax: 75,
            description: "Cloudy",
            iconCode: "04d",
            humidity: 70,
            pressure: 1010,
            windSpeed: 12.3,
            windDirection: 220,
            visibility: 8000,
            lastUpdated: Date()
        ),
        appState.weatherState.cities[2].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[2].id,
            temperature: 58,
            feelsLike: 54,
            temperatureMin: 55,
            temperatureMax: 62,
            description: "Light rain",
            iconCode: "10d",
            humidity: 85,
            pressure: 1008,
            windSpeed: 15.2,
            windDirection: 270,
            visibility: 5000,
            lastUpdated: Date()
        ),
        appState.weatherState.cities[3].id: Weather(
            id: UUID(),
            cityId: appState.weatherState.cities[3].id,
            temperature: 78,
            feelsLike: 82,
            temperatureMin: 72,
            temperatureMax: 85,
            description: "Sunny",
            iconCode: "01d",
            humidity: 45,
            pressure: 1018,
            windSpeed: 6.8,
            windDirection: 90,
            visibility: 15000,
            lastUpdated: Date()
        )
    ]
    
    // Add sample hourly forecasts
    for city in appState.weatherState.cities {
        var hourlyForecast: [HourlyWeather] = []
        for i in 0..<24 {
            let time = Date().addingTimeInterval(TimeInterval(i * 3600))
            let baseTemp = appState.weatherState.weatherData[city.id]?.temperature ?? 70
            let tempVariation = Double.random(in: -5...5)
            
            hourlyForecast.append(HourlyWeather(
                id: UUID(),
                time: time,
                temperature: baseTemp + tempVariation,
                iconCode: ["01d", "02d", "03d", "04d"].randomElement() ?? "01d",
                description: "Partly cloudy"
            ))
        }
        appState.weatherState.hourlyForecasts[city.id] = hourlyForecast
    }
    
    // Add sample daily forecasts
    for city in appState.weatherState.cities {
        var dailyForecast: [DailyWeather] = []
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            let baseTemp = appState.weatherState.weatherData[city.id]?.temperature ?? 70
            let tempVariation = Double.random(in: -10...10)
            
            dailyForecast.append(DailyWeather(
                id: UUID(),
                date: date,
                temperatureMin: baseTemp + tempVariation - 8,
                temperatureMax: baseTemp + tempVariation + 5,
                iconCode: ["01d", "02d", "03d", "04d", "10d"].randomElement() ?? "01d",
                description: "Partly cloudy",
                precipitationChance: Double.random(in: 0...0.8)
            ))
        }
        appState.weatherState.dailyForecasts[city.id] = dailyForecast
    }
    
    appState.weatherState.selectedCityIndex = 0
    
    return AppContainer(appState: appState, interactors: .stub)
}
