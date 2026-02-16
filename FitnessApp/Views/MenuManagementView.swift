//
//  MenuManagementView.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T033: Menu management UI with CRUD for menus and exercises (FR-011, FR-012)
//

import SwiftData
import SwiftUI

/// メニュー管理画面（iPhone）
struct MenuManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MenuViewModel()
    @State private var showNewMenuSheet = false
    @State private var newMenuName = ""

    var body: some View {
        List {
            if self.viewModel.menus.isEmpty {
                // 空状態
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "list.clipboard")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("メニューがありません")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("「+」ボタンからメニューを作成してください")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                ForEach(self.viewModel.menus, id: \.id) { menu in
                    NavigationLink {
                        MenuDetailView(menu: menu, viewModel: self.viewModel)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(menu.name)
                                .font(.headline)
                            Text("\(menu.exercises.count)種目")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        self.viewModel.deleteMenu(self.viewModel.menus[index], modelContext: self.modelContext)
                    }
                }
            }
        }
        .navigationTitle("メニュー管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.showNewMenuSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: self.$showNewMenuSheet) {
            NavigationStack {
                Form {
                    TextField("メニュー名", text: self.$newMenuName)
                }
                .navigationTitle("新しいメニュー")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            self.newMenuName = ""
                            self.showNewMenuSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("作成") {
                            guard !self.newMenuName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            self.viewModel.createMenu(name: self.newMenuName, modelContext: self.modelContext)
                            self.newMenuName = ""
                            self.showNewMenuSheet = false
                        }
                        .disabled(self.newMenuName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            self.viewModel.loadMenus(modelContext: self.modelContext)
        }
    }
}

// MARK: - Menu Detail View

/// メニュー詳細・種目管理画面
struct MenuDetailView: View {
    let menu: TrainingMenu
    @Bindable var viewModel: MenuViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    @State private var newDefaultSets = 3
    @State private var newDefaultWeight = 20.0
    @State private var newDefaultReps = 10

    var sortedExercises: [Exercise] {
        self.menu.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            // メニュー情報
            Section("メニュー情報") {
                Text(self.menu.name)
                    .font(.headline)
            }

            // 種目一覧
            Section("種目") {
                if self.sortedExercises.isEmpty {
                    Text("種目がありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(self.sortedExercises, id: \.id) { exercise in
                        NavigationLink {
                            ExerciseEditView(exercise: exercise, viewModel: self.viewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.subheadline)
                                HStack(spacing: 8) {
                                    Text("\(exercise.defaultSets)セット")
                                    Text("\(exercise.defaultWeight, specifier: "%.1f")kg")
                                    Text("\(exercise.defaultReps)レップ")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            self.viewModel.removeExercise(
                                self.sortedExercises[index],
                                from: self.menu,
                                modelContext: self.modelContext
                            )
                        }
                    }
                    .onMove { from, to in
                        self.viewModel.reorderExercises(
                            in: self.menu,
                            from: from,
                            to: to,
                            modelContext: self.modelContext
                        )
                    }
                }
            }
        }
        .navigationTitle(self.menu.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    self.showAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                EditButton()
            }
        }
        .sheet(isPresented: self.$showAddExercise) {
            NavigationStack {
                Form {
                    TextField("種目名", text: self.$newExerciseName)

                    Stepper("セット数: \(self.newDefaultSets)", value: self.$newDefaultSets, in: 1...20)

                    HStack {
                        Text("重量 (kg)")
                        Spacer()
                        TextField("重量", value: self.$newDefaultWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    Stepper("レップ数: \(self.newDefaultReps)", value: self.$newDefaultReps, in: 1...100)
                }
                .navigationTitle("種目を追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            self.resetExerciseForm()
                            self.showAddExercise = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            guard !self.newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            self.viewModel.addExercise(
                                to: self.menu,
                                name: self.newExerciseName,
                                defaultSets: self.newDefaultSets,
                                defaultWeight: self.newDefaultWeight,
                                defaultReps: self.newDefaultReps,
                                modelContext: self.modelContext
                            )
                            self.resetExerciseForm()
                            self.showAddExercise = false
                        }
                        .disabled(self.newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func resetExerciseForm() {
        self.newExerciseName = ""
        self.newDefaultSets = 3
        self.newDefaultWeight = 20.0
        self.newDefaultReps = 10
    }
}

// MARK: - Exercise Edit View

/// 種目編集画面
struct ExerciseEditView: View {
    let exercise: Exercise
    @Bindable var viewModel: MenuViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var defaultSets = 3
    @State private var defaultWeight = 20.0
    @State private var defaultReps = 10

    var body: some View {
        Form {
            TextField("種目名", text: self.$name)

            Stepper("セット数: \(self.defaultSets)", value: self.$defaultSets, in: 1...20)

            HStack {
                Text("重量 (kg)")
                Spacer()
                TextField("重量", value: self.$defaultWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            Stepper("レップ数: \(self.defaultReps)", value: self.$defaultReps, in: 1...100)
        }
        .navigationTitle("種目編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    self.viewModel.updateExercise(
                        self.exercise,
                        name: self.name,
                        defaultSets: self.defaultSets,
                        defaultWeight: self.defaultWeight,
                        defaultReps: self.defaultReps,
                        modelContext: self.modelContext
                    )
                    self.dismiss()
                }
            }
        }
        .onAppear {
            self.name = self.exercise.name
            self.defaultSets = self.exercise.defaultSets
            self.defaultWeight = self.exercise.defaultWeight
            self.defaultReps = self.exercise.defaultReps
        }
    }
}

#Preview {
    NavigationStack {
        MenuManagementView()
    }
}
