//
//  Exercise.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  Target Membership: iOS only
//

import Foundation
import SwiftData

/// 種目の定義。メニューに所属。
@Model
final class Exercise {
    /// SwiftData主キー
    var id: UUID
    
    /// 種目識別子
    var exerciseId: UUID
    
    /// 種目名
    var name: String
    
    /// デフォルトセット数
    var defaultSets: Int
    
    /// デフォルト重量（kg）。FR-004のワンタップ記録を実現
    var defaultWeight: Double
    
    /// デフォルトレップ数
    var defaultReps: Int
    
    /// メニュー内の種目順序（FR-019の自動遷移順序を決定）
    var sortOrder: Int
    
    /// 親メニュー
    var menu: TrainingMenu?
    
    init(
        exerciseId: UUID = UUID(),
        name: String,
        defaultSets: Int = 3,
        defaultWeight: Double = 20.0,
        defaultReps: Int = 10,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.name = name
        self.defaultSets = defaultSets
        self.defaultWeight = defaultWeight
        self.defaultReps = defaultReps
        self.sortOrder = sortOrder
    }
}
