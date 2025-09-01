//
//  AppEnvironment.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import SwiftData

@MainActor
struct AppEnvironment {
    let option: Option
    let appContainer: AppContainer
    
    enum Option: String {
        case preview
        case local
        case production
    }
    
    static let current: Option = {
        #if PREVIEW
        return .preview
        #elseif DEBUG
        return .local
        #else
        return .production
        #endif
    }()
}

extension AppEnvironment {
    @MainActor
    static func bootstrap(_ optionOverride: AppEnvironment.Option? = nil, modelContext: ModelContext? = nil) -> AppEnvironment {
        let option = optionOverride ?? AppEnvironment.current
        
        switch option {
        case .preview:
            return createPreviewEnvironment()
        case .local:
            return createLocalEnvironment(modelContext: modelContext)
        case .production:
            return createWebEnvironment(option: option, modelContext: modelContext)
        }
    }
    
    @MainActor
    private static func createPreviewEnvironment() -> AppEnvironment {
        let appState = AppState()
        let interactors = createPreviewInteractors(appState: appState)
        let container = AppContainer(appState: appState, interactors: interactors)
        
        return AppEnvironment(option: .preview, appContainer: container)
    }
    
    @MainActor
    private static func createLocalEnvironment(modelContext: ModelContext? = nil) -> AppEnvironment {
        let appState = AppState()
        let interactors = createWebInteractors(appState: appState, modelContext: modelContext)
        let container = AppContainer(appState: appState, interactors: interactors)
        
        return AppEnvironment(option: .local, appContainer: container)
    }
    
    @MainActor
    private static func createWebEnvironment(option: AppEnvironment.Option, modelContext: ModelContext? = nil) -> AppEnvironment {
        let appState = AppState()
        let interactors = createWebInteractors(appState: appState, modelContext: modelContext)
        let container = AppContainer(appState: appState, interactors: interactors)
        
        return AppEnvironment(option: option, appContainer: container)
    }
    
    @MainActor
    private static func createPreviewInteractors(appState: AppState) -> AppContainer.Interactors {
        let weatherInteractor = WeatherInteractor(
            repository: WeatherPreviewRepository(),
            appState: appState
        )
        let locationInteractor = LocationInteractor(
            repository: LocationPreviewRepository(),
            appState: appState
        )
        
        return AppContainer.Interactors(
            weatherInteractor: weatherInteractor,
            locationInteractor: locationInteractor
        )
    }
    
    @MainActor
    private static func createWebInteractors(appState: AppState, modelContext: ModelContext? = nil) -> AppContainer.Interactors {
        let weatherInteractor = WeatherInteractor(
            repository: WeatherWebRepository(modelContext: modelContext),
            appState: appState
        )
        let locationInteractor = LocationInteractor(
            repository: LocationWebRepository(),
            appState: appState
        )
        
        return AppContainer.Interactors(
            weatherInteractor: weatherInteractor,
            locationInteractor: locationInteractor
        )
    }
}