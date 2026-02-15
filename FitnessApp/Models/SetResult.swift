//
//  SetResult.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//

import Foundation
import SwiftData

/// 各セットの個別結果
@Model
final class SetResult {
    /// SwiftData主キー
    var id: UUID
    
    /// セット番号（1始まり）
    var setNumber: Int
    
    /// 重量（kg。NFR-006によりMVPではkg固定）
    var weight: Double
    
    /// レップ数
    var reps: Int
    
    /// セット完了時刻のタイムスタンプ
    var completedAt: Date
    
    /// 親種目結果
    var exerciseResult: ExerciseResult?
    
    init(
        setNumber: Int,
        weight: Double,
        reps: Int,
        completedAt: Date = Date()
    ) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.completedAt = completedAt
    }
}
