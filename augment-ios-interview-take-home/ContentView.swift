//
//  ContentView.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.container) private var container
    @Environment(\.appState) private var appState
    @Environment(\.interactors) private var interactors
    
    var body: some View {
        NavigationStack {
            WeatherListView()
                .navigationTitle("Weather")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await container.addCurrentLocationCity()
                            }
                        } label: {
                            Image(systemName: "location")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: AddCityView()) {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        .task {
            await interactors.weatherInteractor.loadInitialData()
        }
        .refreshable {
            await interactors.weatherInteractor.refreshAllWeather()
        }
    }
}

#Preview {
    ContentView()
        .inject(AppContainer.preview)
}
