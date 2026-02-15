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
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [
            TrainingMenu.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseResult.self,
            SetResult.self
        ])
    }
}
