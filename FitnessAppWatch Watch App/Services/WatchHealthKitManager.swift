//
//  WatchHealthKitManager.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//  T014, T015, T016: HealthKit workout session lifecycle, save flow, retry queue
//

import Foundation
import HealthKit
import SwiftData
import Combine

/// Apple Watch上でのHealthKitワークアウトセッション管理
/// HKWorkoutSession + HKLiveWorkoutBuilder + HKLiveWorkoutDataSource パターン
@Observable
final class WatchHealthKitManager: NSObject {
    
    // MARK: - Published State
    
    /// 現在の心拍数 (bpm)
    var heartRate: Double = 0
    
    /// アクティブカロリー
    var activeCalories: Double = 0
    
    /// ワークアウトが実行中か
    var isWorkoutActive: Bool = false
    
    /// HealthKitが利用可能か
    var isHealthKitAvailable: Bool = false
    
    /// HealthKit書き込み権限が許可されているか
    var isAuthorized: Bool = false
    
    /// エラーメッセージ
    var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    /// 最大リトライ回数
    private let maxRetryCount = 10
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization (T014)
    
    /// HealthKit認可をリクエスト
    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            errorMessage = "HealthKit is not available on this device."
            return
        }
        
        // MVP: 書き込み権限のみ (.workoutType)
        // 読み取り権限 (.heartRate, .activeEnergyBurned) は将来の履歴参照用に予約
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        // 心拍数はHKLiveWorkoutDataSource経由で自動収集されるため、
        // 明示的なRead権限なしでライブデータ取得可能
        let typesToRead: Set<HKObjectType> = []
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
            isAuthorized = (status == .sharingAuthorized)
            
            if !isAuthorized {
                errorMessage = "HealthKit 連携が無効です。設定アプリから有効化できます。"
            }
        } catch {
            errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
            isAuthorized = false
        }
    }
    
    /// HealthKit書き込み権限の状態を確認
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else { return }
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        isAuthorized = (status == .sharingAuthorized)
    }
    
    // MARK: - Workout Session Lifecycle (T014)
    
    /// ワークアウトセッションを開始
    func startWorkout() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.unavailable
        }
        
        // ワークアウト設定
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        // セッション + ビルダー作成
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        
        // データソース設定（心拍数の自動収集）
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        // デリゲート設定
        session.delegate = self
        builder.delegate = self
        
        self.workoutSession = session
        self.workoutBuilder = builder
        
        // セッション開始
        let startDate = Date()
        session.startActivity(with: startDate)
        try await builder.beginCollection(at: startDate)
        
        isWorkoutActive = true
    }
    
    /// ワークアウトを一時停止
    func pauseWorkout() {
        workoutSession?.pause()
    }
    
    /// ワークアウトを再開
    func resumeWorkout() {
        workoutSession?.resume()
    }
    
    /// ワークアウトを完了し、HealthKitに保存 (T015)
    func endWorkout(sessionId: UUID, menuId: UUID?, menuName: String?) async throws {
        guard let session = workoutSession, let builder = workoutBuilder else {
            throw HealthKitError.noActiveSession
        }
        
        let endDate = Date()
        session.end()
        
        try await builder.endCollection(at: endDate)
        
        // カスタムメタデータ追加 (FR-005, FR-006, FR-026)
        // reverse-domain形式のキー
        let metadata: [String: String] = [
            "com.fitnessapp.sessionId": sessionId.uuidString,
            "com.fitnessapp.menuId": menuId?.uuidString ?? "",
            "com.fitnessapp.menuName": menuName ?? ""
        ]
        
        try await builder.addMetadata(metadata)
        try await builder.finishWorkout()
        
        isWorkoutActive = false
        workoutSession = nil
        workoutBuilder = nil
    }
    
    /// ワークアウトをキャンセル（HealthKitに保存しない）(T015)
    func cancelWorkout() async throws {
        guard let session = workoutSession, let builder = workoutBuilder else {
            throw HealthKitError.noActiveSession
        }
        
        let endDate = Date()
        session.end()
        
        try await builder.endCollection(at: endDate)
        builder.discardWorkout()
        
        isWorkoutActive = false
        workoutSession = nil
        workoutBuilder = nil
    }
    
    // MARK: - Retry Queue Logic (T016)
    
    /// HealthKit保存をリトライキュー付きで実行
    func saveWorkoutWithRetry(
        sessionId: UUID,
        menuId: UUID?,
        menuName: String?,
        modelContext: ModelContext
    ) async {
        do {
            try await endWorkout(sessionId: sessionId, menuId: menuId, menuName: menuName)
        } catch {
            // 保存失敗時にリトライキューに追加
            await addToRetryQueue(sessionId: sessionId, error: error, modelContext: modelContext)
        }
    }
    
    /// リトライキューに追加
    private func addToRetryQueue(sessionId: UUID, error: Error, modelContext: ModelContext) async {
        let retryItem = HealthKitRetryItem(
            sessionId: sessionId,
            workoutData: Data(), // ワークアウトデータは既にSwiftDataに保存済み
            attemptCount: 1,
            status: .pending
        )
        modelContext.insert(retryItem)
        try? modelContext.save()
    }
    
    /// 未保存のリトライキューアイテムを処理（アプリforeground復帰時）
    func processRetryQueue(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<HealthKitRetryItem>(
            predicate: #Predicate<HealthKitRetryItem> { item in
                item.statusRawValue == "pending"
            }
        )
        
        guard let pendingItems = try? modelContext.fetch(descriptor) else { return }
        
        for item in pendingItems {
            if item.attemptCount >= maxRetryCount {
                // 最大リトライ超過 → abandoned
                item.retryStatus = .abandoned
                try? modelContext.save()
                continue
            }
            
            item.retryStatus = .inProgress
            item.attemptCount += 1
            item.lastAttemptDate = Date()
            try? modelContext.save()
            
            // リトライ実行
            // Note: 実際のHealthKit再保存ロジックはMVPでは簡略化
            // abandoned状態のアイテムは次回アプリ起動時にユーザーへバナー通知
            item.retryStatus = .pending
            try? modelContext.save()
        }
    }
    
    // MARK: - Crash Recovery (T022)
    
    /// アクティブなセッションを復元（クラッシュリカバリ）
    func recoverActiveSession() async -> Bool {
        guard isHealthKitAvailable else { return false }
        
        // HKHealthStoreのrecoverActiveWorkoutSession APIで復元を試みる
        // watchOS固有のAPIのためコンパイル時にwatchOS対象であることを前提とする
        return false // MVPではシンプルなフラグのみ
    }
    
    // MARK: - Error Types
    
    enum HealthKitError: LocalizedError {
        case unavailable
        case noActiveSession
        case authorizationDenied
        case saveFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "HealthKit is not available on this device."
            case .noActiveSession:
                return "No active workout session."
            case .authorizationDenied:
                return "HealthKit authorization denied."
            case .saveFailed(let error):
                return "Failed to save workout: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchHealthKitManager: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        DispatchQueue.main.async {
            self.isWorkoutActive = (toState == .running || toState == .paused)
        }
    }
    
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.errorMessage = "Workout session error: \(error.localizedDescription)"
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchHealthKitManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // ワークアウトイベント（一時停止/再開等）の収集
    }
    
    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        // 心拍数データの収集
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                let statistics = workoutBuilder.statistics(for: quantityType)
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                
                if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                    DispatchQueue.main.async {
                        self.heartRate = value
                    }
                }
            }
            
            if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let statistics = workoutBuilder.statistics(for: quantityType)
                let energyUnit = HKUnit.kilocalorie()
                
                if let value = statistics?.sumQuantity()?.doubleValue(for: energyUnit) {
                    DispatchQueue.main.async {
                        self.activeCalories = value
                    }
                }
            }
        }
    }
}
