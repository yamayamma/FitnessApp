//
//  FitnessAppApp.swift
//  FitnessApp
//
//  Created by 山口恒大 on 2026/02/11.
//

import SwiftUI
import SwiftData

@main
struct FitnessAppApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for:
                TrainingMenu.self,
                Exercise.self,
                WorkoutSession.self,
                ExerciseResult.self,
                SetResult.self
            )
            
            // WatchConnectivityManagerにModelContextを設定
            WatchConnectivityManager.shared.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(modelContainer)
    }
}
