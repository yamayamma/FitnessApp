//
//  TransferModels.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//  Target Membership: iOS and watchOS
//
//  設計意図: SwiftData @ModelはCodableに自動準拠しないため、
//  WatchConnectivityでのJSONシリアライズには別途CodableなTransfer structが必要。
//  @RelationshipプロパティはJSONシリアライズで循環参照を引き起こすため、
//  フラットなTransferモデルに変換して送信する。
//

import Foundation

// MARK: - Menu Transfer (iPhone → Watch)

/// メニュー同期用Transfer構造体
struct MenuTransfer: Codable {
    let menuId: UUID
    let name: String
    let exercises: [ExerciseTransfer]
}

/// 種目同期用Transfer構造体
struct ExerciseTransfer: Codable {
    let exerciseId: UUID
    let name: String
    let defaultSets: Int
    let defaultWeight: Double
    let defaultReps: Int
    let sortOrder: Int
}

// MARK: - Workout Result Transfer (Watch → iPhone)

/// ワークアウト結果Transfer構造体
struct WorkoutResultTransfer: Codable {
    let sessionId: UUID
    let startDate: Date
    let endDate: Date
    let menuId: UUID?
    let menuName: String?
    let totalDuration: TimeInterval
    let status: String
    let exercises: [ExerciseResultTransfer]
}

/// 種目結果Transfer構造体（sortOrderフィールドを含む - 種目順序のWatch→iPhone転送保証）
struct ExerciseResultTransfer: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let sortOrder: Int
    let sets: [SetResultTransfer]
}

/// セット結果Transfer構造体
struct SetResultTransfer: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let completedAt: Date
}

// MARK: - JSON Encoding/Decoding Helpers

extension JSONEncoder {
    /// アプリ標準のJSONEncoder（ISO 8601日付エンコーディング）
    static let fitnessApp: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    /// アプリ標準のJSONDecoder（ISO 8601日付デコーディング）
    static let fitnessApp: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
