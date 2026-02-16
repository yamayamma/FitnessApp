//
//  WorkoutStatus.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//

import Foundation

/// ワークアウトセッションの状態を表すenum
enum WorkoutStatus: String, Codable, CaseIterable {
    case active // 進行中
    case paused // 一時停止中
    case completed // 完了（HealthKit保存済み）
    case cancelled // キャンセル（HealthKit未保存、ローカルDBに保持）
}
