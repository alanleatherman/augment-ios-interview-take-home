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
        case mock
        case debug
        case production
    }
    
    static let current: Option = {
        #if PREVIEW
        return .preview        // SwiftUI Previews → Mock Data
        #elseif MOCK_DATA
        return .mock          // Mock Scheme → Mock Data  
        #elseif DEBUG
        return .debug         // Debug Scheme → Real API
        #else
        return .production    // Release Scheme → Real API
        #endif
    }()
}

extension AppEnvironment {
    static func bootstrap(_ optionOverride: AppEnvironment.Option? = nil, modelContext: ModelContext? = nil) -> AppEnvironment {
        let option = optionOverride ?? AppEnvironment.current
        print("🌤️ Weather App Environment: \(option.rawValue.uppercased())")
        
        switch option {
        case .preview, .mock:
            print("📱 Using Mock Data Repository (WeatherPreviewRepository)")
            return createMockEnvironment()
        case .debug:
            print("🌐 Using Real API Repository (WeatherWebRepository) - Debug Mode")
            return createDebugEnvironment(modelContext: modelContext)
        case .production:
            print("🚀 Using Real API Repository (WeatherWebRepository) - Production Mode")
            return createProductionEnvironment(modelContext: modelContext)
        }
    }
    
    private static func createMockEnvironment() -> AppEnvironment {
        let appState = AppState()
        let interactors = createMockInteractors(appState: appState)
        let container = AppContainer(appState: appState, interactors: interactors)
        
        return AppEnvironment(option: .mock, appContainer: container)
    }
    
    private static func createDebugEnvironment(modelContext: ModelContext? = nil) -> AppEnvironment {
        let appState = AppState()
        let interactors = createRealAPIInteractors(appState: appState, modelContext: modelContext)
        let container = AppContainer(appState: appState, interactors: interactors)
        
        return AppEnvironment(option: .debug, appContainer: container)
    }
    
    private static func createProductionEnvironment(modelContext: ModelContext? = nil) -> AppEnvironment {
        let appState = AppState()
        let interactors = createRealAPIInteractors(appState: appState, modelContext: modelContext)
        let container = AppContainer(appState: appState, interactors: interactors)
        
        return AppEnvironment(option: .production, appContainer: container)
    }
    
    private static func createMockInteractors(appState: AppState) -> AppContainer.Interactors {
        let weatherInteractor = WeatherInteractor(
            repository: WeatherPreviewRepository(), // Mock data
            appState: appState
        )
        let locationInteractor = LocationInteractor(
            repository: LocationPreviewRepository(), // Mock location
            appState: appState
        )
        
        return AppContainer.Interactors(
            weatherInteractor: weatherInteractor,
            locationInteractor: locationInteractor
        )
    }
    
    private static func createRealAPIInteractors(appState: AppState, modelContext: ModelContext? = nil) -> AppContainer.Interactors {
        let weatherInteractor = WeatherInteractor(
            repository: WeatherWebRepository(modelContext: modelContext, appSettings: appState.appSettings), // Real API
            appState: appState
        )
        let locationInteractor = LocationInteractor(
            repository: LocationWebRepository(), // Real location services
            appState: appState
        )
        
        return AppContainer.Interactors(
            weatherInteractor: weatherInteractor,
            locationInteractor: locationInteractor
        )
    }
}
