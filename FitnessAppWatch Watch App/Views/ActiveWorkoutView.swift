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
            upperArea
            
            Divider()
            
            // 下部エリア: 次セットボタン
            lowerArea
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // 一時停止/再開トグル (FR-022)
                Button {
                    if viewModel.workoutStatus == .paused {
                        viewModel.resumeWorkout()
                    } else {
                        viewModel.pauseWorkout()
                    }
                } label: {
                    Image(systemName: viewModel.workoutStatus == .paused ? "play.fill" : "pause.fill")
                }
            }
        }
        .navigationDestination(isPresented: $showSummary) {
            WorkoutSummaryView(viewModel: viewModel)
        }
        // キャンセル確認ダイアログ (FR-020)
        .confirmationDialog(
            "ワークアウトをキャンセルしますか？",
            isPresented: $viewModel.showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("キャンセル", role: .destructive) {
                Task {
                    await viewModel.cancelWorkout()
                }
            }
            Button("続行", role: .cancel) {}
        }
        .onChange(of: viewModel.isWorkoutCompleted) { _, completed in
            if completed {
                showSummary = true
            }
        }
    }
    
    // MARK: - Upper Area
    
    private var upperArea: some View {
        ScrollView {
            VStack(spacing: 6) {
                // 種目名
                Text(viewModel.currentExerciseName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // フリーワークアウトモード: 種目名入力
                if viewModel.isFreeWorkout && viewModel.currentExercise == nil {
                    TextField("種目名", text: $viewModel.freeExerciseName)
                        .textFieldStyle(.plain)
                        .font(.caption)
                }
                
                // セット数表示
                if !viewModel.isFreeWorkout {
                    Text("セット \(viewModel.currentSetNumber)/\(viewModel.totalSets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("セット \(viewModel.currentSetNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // 重量調整 (±2.5kg per FR-004)
                HStack {
                    Button {
                        viewModel.adjustWeight(by: -2.5)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(viewModel.currentWeight, specifier: "%.1f") kg")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 80)
                    
                    Button {
                        viewModel.adjustWeight(by: 2.5)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
                
                // レップ数調整 (±1 per FR-004)
                HStack {
                    Button {
                        viewModel.adjustReps(by: -1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(viewModel.currentReps) reps")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 80)
                    
                    Button {
                        viewModel.adjustReps(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
                
                // 経過時間・心拍数
                HStack(spacing: 16) {
                    // 経過時間 (MM:SS / H:MM:SS per FR-024)
                    Label(viewModel.elapsedTimeString, systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(viewModel.workoutStatus == .paused ? .yellow : .primary)
                    
                    // 心拍数 (bpm per FR-003)
                    Label(viewModel.heartRateString, systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                // 種目インデックス表示
                if !viewModel.isFreeWorkout && viewModel.totalExercises > 1 {
                    Text("種目 \(viewModel.currentExerciseIndex + 1)/\(viewModel.totalExercises)")
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
            if viewModel.isFreeWorkout && !viewModel.freeExerciseName.isEmpty && viewModel.currentExercise == nil {
                Button {
                    viewModel.addFreeExercise(name: viewModel.freeExerciseName)
                    viewModel.freeExerciseName = ""
                } label: {
                    Text("種目を追加")
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
            }
            
            // 「次セット」ボタン（フルワイド per FR-004）
            Button {
                viewModel.completeSet()
            } label: {
                Text("次セット")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .tint(.green)
            .disabled(viewModel.workoutStatus == .paused)
            
            // ワークアウト完了ボタン
            HStack(spacing: 8) {
                Button {
                    Task {
                        await viewModel.completeWorkout()
                    }
                } label: {
                    Label("完了", systemImage: "checkmark")
                        .font(.caption)
                }
                .tint(.blue)
                
                // キャンセルボタン (FR-020)
                Button {
                    viewModel.showCancelConfirmation = true
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
