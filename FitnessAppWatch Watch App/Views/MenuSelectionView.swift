//
//  MenuSelectionView.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//  T018: Menu selection with empty state UI and free workout option (FR-025)
//

import SwiftData
import SwiftUI

/// メニュー選択画面（Apple Watch）
struct MenuSelectionView: View {
    @Environment(WatchSessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    @State private var workoutViewModel: WorkoutViewModel?
    @State private var isWorkoutActive = false
    @State private var selectedMenu: MenuTransfer?
    @State private var showCrashRecovery = false

    var body: some View {
        NavigationStack {
            List {
                // メニュー一覧
                if self.sessionManager.cachedMenus.isEmpty {
                    // 空状態UI (FR-025)
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "list.clipboard")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("メニューがありません")
                                .font(.headline)
                            Text("iPhoneアプリでメニューを作成してください")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } else {
                    Section("メニュー") {
                        ForEach(self.sessionManager.cachedMenus, id: \.menuId) { menu in
                            Button {
                                self.selectedMenu = menu
                                self.startWorkout(with: menu)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(menu.name)
                                        .font(.headline)
                                    Text("\(menu.exercises.count)種目")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // フリーワークアウト開始オプション
                Section {
                    Button {
                        self.startWorkout(with: nil)
                    } label: {
                        Label("フリーワークアウト", systemImage: "figure.strengthtraining.traditional")
                    }
                }
            }
            .navigationTitle("ワークアウト")
            .navigationDestination(isPresented: self.$isWorkoutActive) {
                if let viewModel = workoutViewModel {
                    ActiveWorkoutView(viewModel: viewModel)
                }
            }
            .alert("未完了のワークアウト", isPresented: self.$showCrashRecovery) {
                Button("続行") {
                    // クラッシュリカバリ: セッション復元
                }
                Button("破棄", role: .destructive) {
                    // キャンセルしてメニュー一覧に戻る
                }
            } message: {
                Text("前回のワークアウトが正常に終了していません。続行しますか？")
            }
            .task {
                // クラッシュリカバリチェック (T022)
                await self.checkForActiveSession()
            }
        }
    }

    // MARK: - Actions

    private func startWorkout(with menu: MenuTransfer?) {
        let viewModel = WorkoutViewModel()
        self.workoutViewModel = viewModel

        Task {
            // HealthKit認可
            await viewModel.healthKitManager.requestAuthorization()

            // ワークアウト開始
            await viewModel.startWorkout(menu: menu, modelContext: self.modelContext)

            self.isWorkoutActive = true
        }
    }

    /// クラッシュリカバリ: 未完了セッションのチェック (T022)
    private func checkForActiveSession() async {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.statusRawValue == "active" || session.statusRawValue == "paused"
            }
        )

        if let activeSessions = try? modelContext.fetch(descriptor),
           !activeSessions.isEmpty
        {
            self.showCrashRecovery = true
        }
    }
}

#Preview {
    MenuSelectionView()
}
