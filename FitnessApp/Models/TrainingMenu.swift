//
//  TrainingMenu.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  Target Membership: iOS only
//

import Foundation
import SwiftData

/// iPhoneで定義するトレーニングメニューのプリセット
@Model
final class TrainingMenu {
    /// SwiftData主キー
    var id: UUID

    /// メニュー識別子（WatchConnectivity同期用）
    var menuId: UUID

    /// メニュー名
    var name: String

    /// 種目の配列
    @Relationship(deleteRule: .cascade, inverse: \Exercise.menu)
    var exercises: [Exercise]

    /// 作成日時
    var createdAt: Date

    /// 最終更新日時
    var updatedAt: Date

    init(
        menuId: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.menuId = menuId
        self.name = name
        self.exercises = []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
