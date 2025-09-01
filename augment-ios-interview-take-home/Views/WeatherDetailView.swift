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
                // Current Weather Card
                if let weather = weather {
                    CurrentWeatherCard(weather: weather)
                } else {
                    LoadingWeatherCard(cityName: city.name)
                }
                
                // Hourly Forecast
                if !hourlyForecast.isEmpty {
                    HourlyForecastView(forecast: hourlyForecast)
                } else if weather != nil {
                    LoadingHourlyForecastView()
                }
                
                // Daily Forecast
                if !dailyForecast.isEmpty {
                    DailyForecastView(forecast: dailyForecast)
                } else if weather != nil {
                    LoadingDailyForecastView()
                }
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

struct LoadingWeatherCard: View {
    let cityName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // City name
            Text(cityName)
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundColor(.primary)
            
            // Loading indicator
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                
                Text("Loading weather...")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 40)
            
            Divider()
            
            // Mock weather details with placeholders
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WeatherDetailPlaceholder(title: "Feels Like")
                WeatherDetailPlaceholder(title: "Humidity")
                WeatherDetailPlaceholder(title: "Wind")
                WeatherDetailPlaceholder(title: "Pressure")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct WeatherDetailPlaceholder: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 20)
                .frame(maxWidth: 60)
        }
    }
}

struct CurrentWeatherCard: View {
    let weather: Weather
    
    var body: some View {
        VStack(spacing: 16) {
            // Temperature and condition
            VStack(spacing: 8) {
                Text(weather.temperatureFormatted)
                    .font(.system(size: 72, weight: .thin))
                
                Text(weather.description.capitalized)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(weather.temperatureRangeFormatted)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Weather details
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                WeatherDetailItem(title: "Feels Like", value: "\(Int(weather.feelsLike.rounded()))°")
                WeatherDetailItem(title: "Humidity", value: "\(weather.humidity)%")
                WeatherDetailItem(title: "Wind", value: "\(Int(weather.windSpeed.rounded())) mph")
                WeatherDetailItem(title: "Pressure", value: "\(weather.pressure) hPa")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct WeatherDetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
    }
}

struct HourlyForecastView: View {
    let forecast: [HourlyWeather]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(forecast.prefix(12)) { hour in
                        VStack(spacing: 8) {
                            Text(hour.timeFormatted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(hour.weatherEmoji)
                                .font(.title2)
                            
                            Text("\(Int(hour.temperature.rounded()))°")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct LoadingHourlyForecastView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<12, id: \.self) { _ in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 30, height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 32, height: 32)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(width: 25, height: 16)
                        }
                        .padding(.vertical, 8)
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct LoadingDailyForecastView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10-Day Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 24, height: 24)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 16)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if index < 9 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct DailyForecastView: View {
    let forecast: [DailyWeather]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10-Day Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(forecast.prefix(10)) { day in
                    HStack {
                        Text(day.dayFormatted)
                            .font(.body)
                            .frame(width: 80, alignment: .leading)
                        
                        Text(day.weatherEmoji)
                            .font(.title3)
                        
                        Spacer()
                        
                        if day.precipitationChance > 0.1 {
                            Text("\(Int(day.precipitationChance * 100))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                        } else {
                            Spacer()
                                .frame(width: 40)
                        }
                        
                        Text("\(Int(day.temperatureMin.rounded()))°")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        
                        Text("\(Int(day.temperatureMax.rounded()))°")
                            .font(.body)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if day.id != forecast.prefix(10).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

#Preview {
    NavigationStack {
        WeatherDetailView(city: City.sample)
    }
    .inject(AppContainer.preview)
}
