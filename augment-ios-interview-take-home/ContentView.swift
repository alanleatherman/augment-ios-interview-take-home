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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        MainWeatherView()
            .task {
                await interactors.weatherInteractor.loadInitialData()
            }
            .refreshable {
                await interactors.weatherInteractor.refreshAllWeather()
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // User is exiting the app - mark current city as home
            interactors.weatherInteractor.markCurrentCityAsHome()
        case .active:
            // App became active - could refresh data if needed
            break
        case .inactive:
            // App is becoming inactive - no action needed
            break
        @unknown default:
            break
        }
    }
}

#Preview {
    ContentView()
        .inject(AppContainer.preview)
}
