//
//  WorkoutView.swift
//  FitnessAppWatch Watch App
//
//  DEPRECATED: This file is replaced by Views/ActiveWorkoutView.swift
//  Kept for backward compatibility reference only.
//  TODO: Remove in next cleanup cycle after verifying no Xcode references remain.
//

import SwiftUI

/// Legacy ContentView - replaced by MenuSelectionView as the root view
struct ContentView: View {
    var body: some View {
        // Redirect to new menu selection flow
        MenuSelectionView()
    }
}

#Preview {
    ContentView()
}
