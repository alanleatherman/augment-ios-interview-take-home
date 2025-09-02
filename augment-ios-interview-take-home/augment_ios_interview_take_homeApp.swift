//
//  augment_ios_interview_take_homeApp.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import SwiftUI
import SwiftData

@main
struct augment_ios_interview_take_homeApp: App {
    @State private var appContainer: AppContainer?
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            City.self,
            CachedWeather.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .inject(getAppContainer())
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await getAppContainer().handleAppDidBecomeActive()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    Task {
                        await getAppContainer().handleAppDidEnterBackground()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func getAppContainer() -> AppContainer {
        if let container = appContainer {
            return container
        }
        
        let container = AppEnvironment.bootstrap(modelContext: sharedModelContainer.mainContext).appContainer
        appContainer = container
        return container
    }
}
