//
//  WeatherPageView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 9/2/25.
//

import SwiftUI

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
        return weather?.temperatureRangeFormatted ?? "H:--° L:--°"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
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
                            .padding(.top, 40)
                        } else {
                            Spacer()
                                .frame(height: 40)
                        }
                        
                        Text(city?.name ?? "Loading...")
                            .font(.largeTitle)
                            .fontWeight(.light)
                            .weatherForegroundColor(for: weather)
                        
                        VStack(spacing: 8) {
                            if let weather = weather {
                                VStack(spacing: 8) {
                                    Text(weather.temperatureFormatted)
                                        .font(.system(size: 96, weight: .thin))
                                        .weatherForegroundColor(for: weather)
                                        .offset(x: 12)
                                    
                                    Text(weather.description.capitalized)
                                        .font(.title2)
                                        .weatherSecondaryForegroundColor(for: weather)
                                    
                                    Text(todayHighLowFormatted)
                                        .font(.title3)
                                        .weatherSecondaryForegroundColor(for: weather)
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            } else {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                        .frame(height: 96)
                                    
                                    Text("Loading weather...")
                                        .font(.title2)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("H:--° L:--°")
                                        .font(.title3)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(minHeight: 160)
                        .animation(.easeInOut(duration: 0.5), value: weather != nil)
                    }
                    .frame(minHeight: geometry.size.height * 0.4)
                    
                    VStack(spacing: 20) {
                        if let weather = weather {
                            Text(weather.detailedDescription ?? "Current conditions will continue.")
                                .font(.body)
                                .weatherSecondaryForegroundColor(for: weather)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Group {
                            if !hourlyForecast.isEmpty {
                                HourlyForecastCard(forecast: hourlyForecast, weather: weather)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            } else {
                                LoadingHourlyForecastCard(weather: weather)
                                    .transition(.opacity)
                            }
                        }
                        .frame(minHeight: 120)
                        .animation(.easeInOut(duration: 0.4), value: hourlyForecast.isEmpty)
                        
                        Group {
                            if !dailyForecast.isEmpty {
                                DailyForecastCard(forecast: dailyForecast, weather: weather)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            } else {
                                LoadingDailyForecastCard(weather: weather)
                                    .transition(.opacity)
                            }
                        }
                        .frame(minHeight: 200)
                        .animation(.easeInOut(duration: 0.4), value: dailyForecast.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
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