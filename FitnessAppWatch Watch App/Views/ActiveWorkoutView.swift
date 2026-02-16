//
//  ActiveWorkoutView.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//  T019: Active workout UI with set progression (FR-002, FR-003, FR-004, FR-020, FR-022, FR-024)
//

import SwiftUI

/// ワークアウト実行画面（Apple Watch）
struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @State private var showSummary = false

    var body: some View {
        VStack(spacing: 0) {
            // 上部エリア: 種目情報・セット情報・心拍数・経過時間
            self.upperArea

            Divider()

            // 下部エリア: 次セットボタン
            self.lowerArea
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // 一時停止/再開トグル (FR-022)
                Button {
                    if self.viewModel.workoutStatus == .paused {
                        self.viewModel.resumeWorkout()
                    } else {
                        self.viewModel.pauseWorkout()
                    }
                } label: {
                    Image(systemName: self.viewModel.workoutStatus == .paused ? "play.fill" : "pause.fill")
                }
            }
        }
        .navigationDestination(isPresented: self.$showSummary) {
            WorkoutSummaryView(viewModel: self.viewModel)
        }
        // キャンセル確認ダイアログ (FR-020)
        .confirmationDialog(
            "ワークアウトをキャンセルしますか？",
            isPresented: self.$viewModel.showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("キャンセル", role: .destructive) {
                Task {
                    await self.viewModel.cancelWorkout()
                }
            }
            Button("続行", role: .cancel) {}
        }
        .onChange(of: self.viewModel.isWorkoutCompleted) { _, completed in
            if completed {
                self.showSummary = true
            }
        }
    }

    // MARK: - Upper Area

    private var upperArea: some View {
        ScrollView {
            VStack(spacing: 6) {
                // 種目名
                Text(self.viewModel.currentExerciseName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // フリーワークアウトモード: 種目名入力
                if self.viewModel.isFreeWorkout, self.viewModel.currentExercise == nil {
                    TextField("種目名", text: self.$viewModel.freeExerciseName)
                        .textFieldStyle(.plain)
                        .font(.caption)
                }

                // セット数表示
                if !self.viewModel.isFreeWorkout {
                    Text("セット \(self.viewModel.currentSetNumber)/\(self.viewModel.totalSets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("セット \(self.viewModel.currentSetNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 重量調整 (±2.5kg per FR-004)
                HStack {
                    Button {
                        self.viewModel.adjustWeight(by: -2.5)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)

                    Text("\(self.viewModel.currentWeight, specifier: "%.1f") kg")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 80)

                    Button {
                        self.viewModel.adjustWeight(by: 2.5)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                // レップ数調整 (±1 per FR-004)
                HStack {
                    Button {
                        self.viewModel.adjustReps(by: -1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)

                    Text("\(self.viewModel.currentReps) reps")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 80)

                    Button {
                        self.viewModel.adjustReps(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                // 経過時間・心拍数
                HStack(spacing: 16) {
                    // 経過時間 (MM:SS / H:MM:SS per FR-024)
                    Label(self.viewModel.elapsedTimeString, systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(self.viewModel.workoutStatus == .paused ? .yellow : .primary)

                    // 心拍数 (bpm per FR-003)
                    Label(self.viewModel.heartRateString, systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // 種目インデックス表示
                if !self.viewModel.isFreeWorkout, self.viewModel.totalExercises > 1 {
                    Text("種目 \(self.viewModel.currentExerciseIndex + 1)/\(self.viewModel.totalExercises)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }

    // MARK: - Lower Area

    private var lowerArea: some View {
        VStack(spacing: 4) {
            // フリーワークアウト: 種目追加ボタン
            if self.viewModel.isFreeWorkout, !self.viewModel.freeExerciseName.isEmpty,
               self.viewModel.currentExercise == nil
            {
                Button {
                    self.viewModel.addFreeExercise(name: self.viewModel.freeExerciseName)
                    self.viewModel.freeExerciseName = ""
                } label: {
                    Text("種目を追加")
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
            }

            // 「次セット」ボタン（フルワイド per FR-004）
            Button {
                self.viewModel.completeSet()
            } label: {
                Text("次セット")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .tint(.green)
            .disabled(self.viewModel.workoutStatus == .paused)

            // ワークアウト完了ボタン
            HStack(spacing: 8) {
                Button {
                    Task {
                        await self.viewModel.completeWorkout()
                    }
                } label: {
                    Label("完了", systemImage: "checkmark")
                        .font(.caption)
                }
                .tint(.blue)

                // キャンセルボタン (FR-020)
                Button {
                    self.viewModel.showCancelConfirmation = true
                } label: {
                    Label("中止", systemImage: "xmark")
                        .font(.caption)
                }
                .tint(.red)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}
