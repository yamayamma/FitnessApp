//
//  ExerciseResult.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//

import Foundation
import SwiftData

/// セッション内の各種目の実行結果
@Model
final class ExerciseResult {
    /// SwiftData主キー
    var id: UUID
    
    /// 種目定義へのUUID値参照（@Relationshipではなく値コピー）
    /// watchOS側にTrainingMenu/Exerciseエンティティが存在しないため
    var exerciseId: UUID
    
    /// 種目名（表示用、非正規化）
    var exerciseName: String
    
    /// セッション内の種目順序（FR-019の種目自動遷移順序を実現）
    var sortOrder: Int
    
    /// セット結果の配列
    @Relationship(deleteRule: .cascade, inverse: \SetResult.exerciseResult)
    var setResults: [SetResult]
    
    /// 親セッション
    var session: WorkoutSession?
    
    init(
        exerciseId: UUID = UUID(),
        exerciseName: String,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sortOrder = sortOrder
        self.setResults = []
    }
}
