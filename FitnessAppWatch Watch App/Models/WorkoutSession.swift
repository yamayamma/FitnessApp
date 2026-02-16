//
//  WorkoutSession.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//

import Foundation
import SwiftData

/// ワークアウトセッションの全体を表す。HealthKitのHKWorkoutとsessionIdで紐付ける。
@Model
final class WorkoutSession {
    /// SwiftData主キー（自動生成）
    var id: UUID

    /// HealthKit metadata・WatchConnectivity transferとの紐付けキー
    /// クロスシステム識別子として、ローカルDBとは別に必要
    @Attribute(.unique)
    var sessionId: UUID

    /// ワークアウト開始時刻
    var startDate: Date

    /// ワークアウト終了時刻（active/paused中はnil）
    var endDate: Date?

    /// 使用したメニューのID（メニューなし開始も許可）
    var menuId: UUID?

    /// メニュー名（表示用、非正規化）
    var menuName: String?

    /// 合計ワークアウト時間（秒）
    var totalDuration: TimeInterval

    /// セッション状態（rawValueで保存）
    var statusRawValue: String

    /// セッション状態の computed property
    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: self.statusRawValue) ?? .active }
        set { self.statusRawValue = newValue.rawValue }
    }

    /// 種目結果の配列
    @Relationship(deleteRule: .cascade, inverse: \ExerciseResult.session)
    var exerciseResults: [ExerciseResult]

    /// レコード作成時刻
    var createdAt: Date

    init(
        sessionId: UUID = UUID(),
        startDate: Date = Date(),
        menuId: UUID? = nil,
        menuName: String? = nil,
        totalDuration: TimeInterval = 0
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.startDate = startDate
        self.endDate = nil
        self.menuId = menuId
        self.menuName = menuName
        self.totalDuration = totalDuration
        self.statusRawValue = WorkoutStatus.active.rawValue
        self.exerciseResults = []
        self.createdAt = Date()
    }
}
