//
//  HealthKitRetryItem.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  Target Membership: watchOS only (FR-015)
//

import Foundation
import SwiftData

/// HealthKit保存のリトライキューアイテム
/// 永続化方式: SwiftData @ModelとしてWatchローカルDBに保存
/// UserDefaultsはサイズ制約のため不採用
@Model
final class HealthKitRetryItem {
    /// 対象のセッションID
    var sessionId: UUID

    /// WorkoutResultTransferのJSON Data
    var workoutData: Data

    /// リトライ試行回数
    var attemptCount: Int

    /// 最終試行日時
    var lastAttemptDate: Date

    /// リトライステータス（rawValueで保存）
    var statusRawValue: String

    /// リトライステータスの computed property
    var retryStatus: RetryStatus {
        get { RetryStatus(rawValue: self.statusRawValue) ?? .pending }
        set { self.statusRawValue = newValue.rawValue }
    }

    init(
        sessionId: UUID,
        workoutData: Data,
        attemptCount: Int = 0,
        lastAttemptDate: Date = Date(),
        status: RetryStatus = .pending
    ) {
        self.sessionId = sessionId
        self.workoutData = workoutData
        self.attemptCount = attemptCount
        self.lastAttemptDate = lastAttemptDate
        self.statusRawValue = status.rawValue
    }
}

/// リトライステータス
enum RetryStatus: String, Codable {
    case pending // 未処理
    case inProgress // 処理中
    case succeeded // 成功
    case abandoned // 最大リトライ超過（>= 10回）
}
