//
//  MenuViewModel.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T032: Menu management ViewModel with CRUD and WatchConnectivity sync
//

import Foundation
import SwiftData
import SwiftUI

/// メニュー管理のViewModel（iPhone側）
@Observable
final class MenuViewModel {
    /// メニュー一覧
    var menus: [TrainingMenu] = []

    // MARK: - Data Loading

    /// メニュー一覧を読み込み
    func loadMenus(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<TrainingMenu>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            self.menus = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch menus: \(error)")
            self.menus = []
        }
    }

    // MARK: - CRUD Operations

    /// 新しいメニューを作成 (FR-011)
    func createMenu(name: String, modelContext: ModelContext) {
        let menu = TrainingMenu(name: name)
        modelContext.insert(menu)

        do {
            try modelContext.save()
            self.loadMenus(modelContext: modelContext)
            self.syncToWatch()
        } catch {
            print("Failed to create menu: \(error)")
        }
    }

    /// メニュー名を更新
    func updateMenu(_ menu: TrainingMenu, name: String, modelContext: ModelContext) {
        menu.name = name
        menu.updatedAt = Date()

        do {
            try modelContext.save()
            self.loadMenus(modelContext: modelContext)
            self.syncToWatch()
        } catch {
            print("Failed to update menu: \(error)")
        }
    }

    /// メニューを削除
    func deleteMenu(_ menu: TrainingMenu, modelContext: ModelContext) {
        modelContext.delete(menu)

        do {
            try modelContext.save()
            self.loadMenus(modelContext: modelContext)
            self.syncToWatch()
        } catch {
            print("Failed to delete menu: \(error)")
        }
    }

    // MARK: - Exercise Operations

    /// メニューに種目を追加 (FR-012)
    func addExercise(
        to menu: TrainingMenu,
        name: String,
        defaultSets: Int = 3,
        defaultWeight: Double = 20.0,
        defaultReps: Int = 10,
        modelContext: ModelContext
    ) {
        let sortOrder = menu.exercises.count
        let exercise = Exercise(
            name: name,
            defaultSets: defaultSets,
            defaultWeight: defaultWeight,
            defaultReps: defaultReps,
            sortOrder: sortOrder
        )
        exercise.menu = menu
        menu.exercises.append(exercise)
        menu.updatedAt = Date()

        modelContext.insert(exercise)

        do {
            try modelContext.save()
            self.syncToWatch()
        } catch {
            print("Failed to add exercise: \(error)")
        }
    }

    /// 種目を削除
    func removeExercise(_ exercise: Exercise, from menu: TrainingMenu, modelContext: ModelContext) {
        menu.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
        menu.updatedAt = Date()

        // sortOrderを再計算
        let sortedExercises = menu.exercises.sorted { $0.sortOrder < $1.sortOrder }
        for (index, ex) in sortedExercises.enumerated() {
            ex.sortOrder = index
        }

        do {
            try modelContext.save()
            self.syncToWatch()
        } catch {
            print("Failed to remove exercise: \(error)")
        }
    }

    /// 種目を並び替え
    func reorderExercises(
        in menu: TrainingMenu,
        from source: IndexSet,
        to destination: Int,
        modelContext: ModelContext
    ) {
        var exercises = menu.exercises.sorted { $0.sortOrder < $1.sortOrder }
        exercises.move(fromOffsets: source, toOffset: destination)

        for (index, exercise) in exercises.enumerated() {
            exercise.sortOrder = index
        }
        menu.updatedAt = Date()

        do {
            try modelContext.save()
            self.syncToWatch()
        } catch {
            print("Failed to reorder exercises: \(error)")
        }
    }

    /// 種目のデフォルト値を更新
    func updateExercise(
        _ exercise: Exercise,
        name: String? = nil,
        defaultSets: Int? = nil,
        defaultWeight: Double? = nil,
        defaultReps: Int? = nil,
        modelContext: ModelContext
    ) {
        if let name { exercise.name = name }
        if let sets = defaultSets { exercise.defaultSets = sets }
        if let weight = defaultWeight { exercise.defaultWeight = weight }
        if let reps = defaultReps { exercise.defaultReps = reps }

        exercise.menu?.updatedAt = Date()

        do {
            try modelContext.save()
            self.syncToWatch()
        } catch {
            print("Failed to update exercise: \(error)")
        }
    }

    // MARK: - WatchConnectivity Sync (T034)

    /// 全メニューをWatchに同期 (FR-013)
    private func syncToWatch() {
        let transfers = self.menus.map { menu in
            MenuTransfer(
                menuId: menu.menuId,
                name: menu.name,
                exercises: menu.exercises
                    .sorted { $0.sortOrder < $1.sortOrder }
                    .map { exercise in
                        ExerciseTransfer(
                            exerciseId: exercise.exerciseId,
                            name: exercise.name,
                            defaultSets: exercise.defaultSets,
                            defaultWeight: exercise.defaultWeight,
                            defaultReps: exercise.defaultReps,
                            sortOrder: exercise.sortOrder
                        )
                    }
            )
        }

        WatchConnectivityManager.shared.syncMenus(transfers)
    }
}
