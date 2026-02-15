//
//  MenuManagementView.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T033: Menu management UI with CRUD for menus and exercises (FR-011, FR-012)
//

import SwiftUI
import SwiftData

/// メニュー管理画面（iPhone）
struct MenuManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MenuViewModel()
    @State private var showNewMenuSheet = false
    @State private var newMenuName = ""
    
    var body: some View {
        List {
            if viewModel.menus.isEmpty {
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
                ForEach(viewModel.menus, id: \.id) { menu in
                    NavigationLink {
                        MenuDetailView(menu: menu, viewModel: viewModel)
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
                        viewModel.deleteMenu(viewModel.menus[index], modelContext: modelContext)
                    }
                }
            }
        }
        .navigationTitle("メニュー管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewMenuSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewMenuSheet) {
            NavigationStack {
                Form {
                    TextField("メニュー名", text: $newMenuName)
                }
                .navigationTitle("新しいメニュー")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            newMenuName = ""
                            showNewMenuSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("作成") {
                            guard !newMenuName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            viewModel.createMenu(name: newMenuName, modelContext: modelContext)
                            newMenuName = ""
                            showNewMenuSheet = false
                        }
                        .disabled(newMenuName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            viewModel.loadMenus(modelContext: modelContext)
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
        menu.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var body: some View {
        List {
            // メニュー情報
            Section("メニュー情報") {
                Text(menu.name)
                    .font(.headline)
            }
            
            // 種目一覧
            Section("種目") {
                if sortedExercises.isEmpty {
                    Text("種目がありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedExercises, id: \.id) { exercise in
                        NavigationLink {
                            ExerciseEditView(exercise: exercise, viewModel: viewModel)
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
                            viewModel.removeExercise(sortedExercises[index], from: menu, modelContext: modelContext)
                        }
                    }
                    .onMove { from, to in
                        viewModel.reorderExercises(in: menu, from: from, to: to, modelContext: modelContext)
                    }
                }
            }
        }
        .navigationTitle(menu.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddExercise) {
            NavigationStack {
                Form {
                    TextField("種目名", text: $newExerciseName)
                    
                    Stepper("セット数: \(newDefaultSets)", value: $newDefaultSets, in: 1...20)
                    
                    HStack {
                        Text("重量 (kg)")
                        Spacer()
                        TextField("重量", value: $newDefaultWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    Stepper("レップ数: \(newDefaultReps)", value: $newDefaultReps, in: 1...100)
                }
                .navigationTitle("種目を追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            resetExerciseForm()
                            showAddExercise = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            guard !newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            viewModel.addExercise(
                                to: menu,
                                name: newExerciseName,
                                defaultSets: newDefaultSets,
                                defaultWeight: newDefaultWeight,
                                defaultReps: newDefaultReps,
                                modelContext: modelContext
                            )
                            resetExerciseForm()
                            showAddExercise = false
                        }
                        .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func resetExerciseForm() {
        newExerciseName = ""
        newDefaultSets = 3
        newDefaultWeight = 20.0
        newDefaultReps = 10
    }
}

// MARK: - Exercise Edit View

/// 種目編集画面
struct ExerciseEditView: View {
    let exercise: Exercise
    @Bindable var viewModel: MenuViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var defaultSets: Int = 3
    @State private var defaultWeight: Double = 20.0
    @State private var defaultReps: Int = 10
    
    var body: some View {
        Form {
            TextField("種目名", text: $name)
            
            Stepper("セット数: \(defaultSets)", value: $defaultSets, in: 1...20)
            
            HStack {
                Text("重量 (kg)")
                Spacer()
                TextField("重量", value: $defaultWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            Stepper("レップ数: \(defaultReps)", value: $defaultReps, in: 1...100)
        }
        .navigationTitle("種目編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    viewModel.updateExercise(
                        exercise,
                        name: name,
                        defaultSets: defaultSets,
                        defaultWeight: defaultWeight,
                        defaultReps: defaultReps,
                        modelContext: modelContext
                    )
                    dismiss()
                }
            }
        }
        .onAppear {
            name = exercise.name
            defaultSets = exercise.defaultSets
            defaultWeight = exercise.defaultWeight
            defaultReps = exercise.defaultReps
        }
    }
}

#Preview {
    NavigationStack {
        MenuManagementView()
    }
}
