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
                .inject(AppEnvironment.bootstrap(modelContext: sharedModelContainer.mainContext).appContainer)
        }
        .modelContainer(sharedModelContainer)
    }
}
