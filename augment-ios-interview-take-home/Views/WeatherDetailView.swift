//
//  WeatherDetailView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import SwiftUI

struct WeatherDetailView: View {
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
        ScrollView {
            VStack(spacing: 20) {
                if let weather = weather {
                    CurrentWeatherCard(weather: weather)
                } else {
                    LoadingWeatherCard(cityName: city.name)
                }
                
                Group {
                    if !hourlyForecast.isEmpty {
                        HourlyForecastView(forecast: hourlyForecast)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        LoadingHourlyForecastView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: hourlyForecast.isEmpty)
                
                Group {
                    if !dailyForecast.isEmpty {
                        DailyForecastView(forecast: dailyForecast)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        LoadingDailyForecastView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: dailyForecast.isEmpty)
            }
            .padding()
        }
        .navigationTitle(city.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadForecastData()
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private func loadForecastData() async {
        await interactors.weatherInteractor.loadHourlyForecast(for: city)
        await interactors.weatherInteractor.loadDailyForecast(for: city)
    }
    
    private func refreshData() async {
        await interactors.weatherInteractor.refreshWeather(for: city)
        await loadForecastData()
    }
}



#Preview {
    NavigationStack {
        WeatherDetailView(city: City.sample)
    }
    .inject(AppContainer.preview)
}
