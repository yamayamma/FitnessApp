//
//  WorkoutViewModel.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//  T017, T021: Workout state management, exercise auto-transition
//

import Foundation
import SwiftData
import Combine

/// ワークアウト実行のViewModel（Apple Watch）
@Observable
final class WorkoutViewModel {
    
    // MARK: - Workout State
    
    /// 現在のワークアウト状態
    var workoutStatus: WorkoutStatus = .active
    
    /// 経過時間（秒）
    var elapsedTime: TimeInterval = 0
    
    /// 経過時間の表示文字列 (MM:SS or H:MM:SS per FR-024)
    var elapsedTimeString: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 心拍数 (bpm)
    var heartRate: Double = 0
    
    /// 心拍数の表示文字列
    var heartRateString: String {
        heartRate > 0 ? "\(Int(heartRate)) bpm" : "-- bpm"
    }
    
    // MARK: - Exercise/Set Tracking
    
    /// 現在のセッション
    var currentSession: WorkoutSession?
    
    /// 種目リスト（メニューまたはフリーワークアウトから）
    var exercises: [ExerciseInfo] = []
    
    /// 現在の種目インデックス
    var currentExerciseIndex: Int = 0
    
    /// 現在のセット番号（1始まり）
    var currentSetNumber: Int = 1
    
    /// 現在の重量 (kg)
    var currentWeight: Double = 20.0
    
    /// 現在のレップ数
    var currentReps: Int = 10
    
    /// フリーワークアウトモードか
    var isFreeWorkout: Bool = false
    
    /// フリーワークアウトの種目名入力
    var freeExerciseName: String = ""
    
    /// キャンセル確認ダイアログの表示
    var showCancelConfirmation: Bool = false
    
    /// ワークアウト完了フラグ
    var isWorkoutCompleted: Bool = false
    
    /// HealthKitマネージャー
    var healthKitManager: WatchHealthKitManager
    
    // MARK: - Current Exercise Info
    
    /// 現在の種目情報
    var currentExercise: ExerciseInfo? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    /// 現在の種目名
    var currentExerciseName: String {
        if isFreeWorkout && currentExercise == nil {
            return freeExerciseName.isEmpty ? "種目を入力" : freeExerciseName
        }
        return currentExercise?.name ?? "種目なし"
    }
    
    /// 総セット数
    var totalSets: Int {
        currentExercise?.defaultSets ?? 0
    }
    
    /// 種目の総数
    var totalExercises: Int {
        exercises.count
    }
    
    // MARK: - Summary Data
    
    /// 完了した種目数
    var completedExerciseCount: Int {
        currentSession?.exerciseResults.count ?? 0
    }
    
    /// 完了した総セット数
    var completedTotalSets: Int {
        currentSession?.exerciseResults.reduce(0) { $0 + $1.setResults.count } ?? 0
    }
    
    // MARK: - Private
    
    private var timer: Timer?
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init(healthKitManager: WatchHealthKitManager = WatchHealthKitManager()) {
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - Workout Lifecycle
    
    /// メニューからワークアウトを開始
    func startWorkout(
        menu: MenuTransfer?,
        modelContext: ModelContext
    ) async {
        self.modelContext = modelContext
        
        let sessionId = UUID()
        
        // セッション作成
        let session = WorkoutSession(
            sessionId: sessionId,
            startDate: Date(),
            menuId: menu?.menuId,
            menuName: menu?.name,
            status: .active
        )
        modelContext.insert(session)
        self.currentSession = session
        
        // メニューから種目情報を設定
        if let menu = menu {
            isFreeWorkout = false
            exercises = menu.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }).map { exercise in
                ExerciseInfo(
                    exerciseId: exercise.exerciseId,
                    name: exercise.name,
                    defaultSets: exercise.defaultSets,
                    defaultWeight: exercise.defaultWeight,
                    defaultReps: exercise.defaultReps,
                    sortOrder: exercise.sortOrder
                )
            }
            
            // 最初の種目のデフォルト値を設定
            if let firstExercise = exercises.first {
                currentWeight = firstExercise.defaultWeight
                currentReps = firstExercise.defaultReps
            }
        } else {
            // フリーワークアウトモード
            isFreeWorkout = true
            exercises = []
        }
        
        currentExerciseIndex = 0
        currentSetNumber = 1
        workoutStatus = .active
        elapsedTime = 0
        
        // ExerciseResultを作成（メニューベースの場合）
        if !isFreeWorkout {
            createExerciseResults(for: session, in: modelContext)
        }
        
        // タイマー開始
        startTimer()
        
        // HealthKit開始
        if healthKitManager.isHealthKitAvailable {
            do {
                try await healthKitManager.startWorkout()
            } catch {
                // HealthKit使用不可でもローカルDBには記録続行
                print("HealthKit start failed: \(error)")
            }
        }
        
        try? modelContext.save()
    }
    
    /// 種目結果をセッションに作成
    private func createExerciseResults(for session: WorkoutSession, in context: ModelContext) {
        for exercise in exercises {
            let result = ExerciseResult(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.name,
                sortOrder: exercise.sortOrder
            )
            result.session = session
            session.exerciseResults.append(result)
            context.insert(result)
        }
    }
    
    /// フリーワークアウトで種目を追加
    func addFreeExercise(name: String) {
        guard let session = currentSession, let context = modelContext else { return }
        
        let exerciseInfo = ExerciseInfo(
            exerciseId: UUID(),
            name: name,
            defaultSets: 0, // フリーワークアウトではセット数無制限
            defaultWeight: currentWeight,
            defaultReps: currentReps,
            sortOrder: exercises.count
        )
        exercises.append(exerciseInfo)
        currentExerciseIndex = exercises.count - 1
        currentSetNumber = 1
        
        let result = ExerciseResult(
            exerciseId: exerciseInfo.exerciseId,
            exerciseName: name,
            sortOrder: exerciseInfo.sortOrder
        )
        result.session = session
        session.exerciseResults.append(result)
        context.insert(result)
        try? context.save()
    }
    
    // MARK: - Set Operations
    
    /// 重量を調整 (±2.5kg per FR-004)
    func adjustWeight(by amount: Double) {
        currentWeight = max(0, currentWeight + amount)
    }
    
    /// レップ数を調整 (±1 per FR-004)
    func adjustReps(by amount: Int) {
        currentReps = max(0, currentReps + amount)
    }
    
    /// セットを完了して次に進む (FR-007, FR-017)
    func completeSet() {
        guard let session = currentSession, let context = modelContext else { return }
        
        // 現在の種目のExerciseResultを取得
        let exerciseResult: ExerciseResult
        if currentExerciseIndex < session.exerciseResults.count {
            // sortOrderでソートして取得
            let sortedResults = session.exerciseResults.sorted { $0.sortOrder < $1.sortOrder }
            exerciseResult = sortedResults[currentExerciseIndex]
        } else {
            return
        }
        
        // SetResultを作成してインクリメンタル保存
        let setResult = SetResult(
            setNumber: currentSetNumber,
            weight: currentWeight,
            reps: currentReps,
            completedAt: Date()
        )
        setResult.exerciseResult = exerciseResult
        exerciseResult.setResults.append(setResult)
        context.insert(setResult)
        
        // 即時保存 (FR-017)
        try? context.save()
        
        // 次のセットまたは種目遷移 (T021 - FR-019)
        advanceToNext()
    }
    
    /// 次のセットまたは種目に進む (T021)
    private func advanceToNext() {
        let isLastSet: Bool
        
        if isFreeWorkout {
            // フリーワークアウトモード: セット数無制限
            currentSetNumber += 1
            return
        }
        
        if let exercise = currentExercise {
            isLastSet = currentSetNumber >= exercise.defaultSets
        } else {
            isLastSet = true
        }
        
        if isLastSet {
            // 最終セット完了
            if currentExerciseIndex >= exercises.count - 1 {
                // 最終種目の最終セット → ワークアウト完了
                return // ユーザーが明示的に完了を選択
            } else {
                // 次種目に自動遷移 (FR-019)
                moveToNextExercise()
            }
        } else {
            // 次セットへ
            currentSetNumber += 1
        }
    }
    
    /// 次の種目に移動
    func moveToNextExercise() {
        guard currentExerciseIndex < exercises.count - 1 else { return }
        currentExerciseIndex += 1
        currentSetNumber = 1
        
        // 次の種目のデフォルト値を設定
        if let exercise = currentExercise {
            currentWeight = exercise.defaultWeight
            currentReps = exercise.defaultReps
        }
    }
    
    /// 前の種目に移動
    func moveToPreviousExercise() {
        guard currentExerciseIndex > 0 else { return }
        currentExerciseIndex -= 1
        currentSetNumber = 1
        
        if let exercise = currentExercise {
            currentWeight = exercise.defaultWeight
            currentReps = exercise.defaultReps
        }
    }
    
    // MARK: - Pause/Resume
    
    /// 一時停止
    func pauseWorkout() {
        workoutStatus = .paused
        stopTimer()
        healthKitManager.pauseWorkout()
        
        currentSession?.status = .paused
        try? modelContext?.save()
    }
    
    /// 再開
    func resumeWorkout() {
        workoutStatus = .active
        startTimer()
        healthKitManager.resumeWorkout()
        
        currentSession?.status = .active
        try? modelContext?.save()
    }
    
    // MARK: - Complete/Cancel
    
    /// ワークアウトを完了
    func completeWorkout() async {
        guard let session = currentSession, let context = modelContext else { return }
        
        stopTimer()
        
        session.endDate = Date()
        session.totalDuration = elapsedTime
        session.status = .completed
        try? context.save()
        
        // HealthKitに保存 (T015)
        if healthKitManager.isHealthKitAvailable && healthKitManager.isAuthorized {
            await healthKitManager.saveWorkoutWithRetry(
                sessionId: session.sessionId,
                menuId: session.menuId,
                menuName: session.menuName,
                modelContext: context
            )
        }
        
        workoutStatus = .completed
        isWorkoutCompleted = true
    }
    
    /// ワークアウトをキャンセル (FR-020)
    func cancelWorkout() async {
        guard let session = currentSession, let context = modelContext else { return }
        
        stopTimer()
        
        session.endDate = Date()
        session.totalDuration = elapsedTime
        session.status = .cancelled
        try? context.save()
        
        // HealthKitからは破棄
        if healthKitManager.isWorkoutActive {
            try? await healthKitManager.cancelWorkout()
        }
        
        workoutStatus = .cancelled
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            
            // HealthKitから心拍数を更新
            self.heartRate = self.healthKitManager.heartRate
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopTimer()
        workoutSession = nil
    }
    
    private var workoutSession_ref: WorkoutSession? = nil
}

// MARK: - ExerciseInfo (Menu Transfer → ViewModel用構造体)

/// ViewModel内で使用する種目情報
struct ExerciseInfo: Identifiable {
    let id = UUID()
    let exerciseId: UUID
    let name: String
    let defaultSets: Int
    let defaultWeight: Double
    let defaultReps: Int
    let sortOrder: Int
}
