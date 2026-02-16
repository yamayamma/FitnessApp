//
//  FitnessAppApp.swift
//  FitnessApp
//
//  Created by 山口恒大 on 2026/02/11.
//

import SwiftData
import SwiftUI

@main
struct FitnessAppApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            self.modelContainer = try ModelContainer(
                for:
                TrainingMenu.self,
                Exercise.self,
                WorkoutSession.self,
                ExerciseResult.self,
                SetResult.self
            )

            // WatchConnectivityManagerにModelContextを設定
            WatchConnectivityManager.shared.modelContext = self.modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(self.modelContainer)
    }
}
