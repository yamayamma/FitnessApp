//
//  FitnessAppWatchApp.swift
//  FitnessAppWatch Watch App
//
//  Created by 山口恒大 on 2026/02/11.
//

import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct FitnessAppWatch_Watch_AppApp: App {
    @State private var watchSessionManager = WatchSessionManager()
    
    var body: some Scene {
        WindowGroup {
            MenuSelectionView()
                .environment(watchSessionManager)
        }
        .modelContainer(for: [
            WorkoutSession.self,
            ExerciseResult.self,
            SetResult.self,
            HealthKitRetryItem.self
        ])
    }
}
