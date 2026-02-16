//
//  FitnessAppWatchApp.swift
//  FitnessAppWatch Watch App
//
//  Created by 山口恒大 on 2026/02/11.
//

import SwiftData
import SwiftUI
import WatchConnectivity

@main
struct FitnessAppWatch_Watch_AppApp: App {
    @State private var watchSessionManager = WatchSessionManager()

    let modelContainer: ModelContainer

    init() {
        do {
            self.modelContainer = try ModelContainer(
                for:
                WorkoutSession.self,
                ExerciseResult.self,
                SetResult.self,
                HealthKitRetryItem.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MenuSelectionView()
                .environment(self.watchSessionManager)
        }
        .modelContainer(self.modelContainer)
    }
}
