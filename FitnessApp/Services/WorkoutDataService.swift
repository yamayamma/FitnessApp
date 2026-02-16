//
//  WorkoutDataService.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T025: Receive and persist workout results from Watch
//

import Foundation
import SwiftData

/// ワークアウトデータの受信・永続化サービス（iPhone側）
enum WorkoutDataService {
    /// Watch からの WorkoutResultTransfer を受信してSwiftDataに保存
    /// - Parameters:
    ///   - transferData: JSONエンコードされたWorkoutResultTransfer Data
    ///   - modelContext: SwiftData ModelContext
    /// - Returns: 保存成功かどうか
    @discardableResult
    static func receiveAndPersist(
        transferData: Data,
        modelContext: ModelContext
    ) -> Bool {
        do {
            let transfer = try JSONDecoder.fitnessApp.decode(
                WorkoutResultTransfer.self,
                from: transferData
            )
            return self.persist(transfer: transfer, modelContext: modelContext)
        } catch {
            print("Failed to decode workout result: \(error)")
            return false
        }
    }

    /// WorkoutResultTransfer をSwiftDataに永続化
    /// - Parameters:
    ///   - transfer: デコード済みのWorkoutResultTransfer
    ///   - modelContext: SwiftData ModelContext
    /// - Returns: 保存成功かどうか
    static func persist(
        transfer: WorkoutResultTransfer,
        modelContext: ModelContext
    ) -> Bool {
        // sessionId ベースの重複チェック (FR-026)
        let sessionId = transfer.sessionId
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.sessionId == sessionId
            }
        )

        if let existingSessions = try? modelContext.fetch(descriptor),
           !existingSessions.isEmpty
        {
            print("Duplicate sessionId detected, skipping: \(sessionId)")
            return false
        }

        // WorkoutSession作成
        let session = WorkoutSession(
            sessionId: transfer.sessionId,
            startDate: transfer.startDate,
            endDate: transfer.endDate,
            menuId: transfer.menuId,
            menuName: transfer.menuName,
            totalDuration: transfer.totalDuration,
            status: WorkoutStatus(rawValue: transfer.status) ?? .completed,
            createdAt: Date()
        )
        modelContext.insert(session)

        // ExerciseResult + SetResult 作成
        for exerciseTransfer in transfer.exercises {
            let exerciseResult = ExerciseResult(
                exerciseId: exerciseTransfer.exerciseId,
                exerciseName: exerciseTransfer.exerciseName,
                sortOrder: exerciseTransfer.sortOrder
            )
            exerciseResult.session = session
            session.exerciseResults.append(exerciseResult)
            modelContext.insert(exerciseResult)

            for setTransfer in exerciseTransfer.sets {
                let setResult = SetResult(
                    setNumber: setTransfer.setNumber,
                    weight: setTransfer.weight,
                    reps: setTransfer.reps,
                    completedAt: setTransfer.completedAt
                )
                setResult.exerciseResult = exerciseResult
                exerciseResult.setResults.append(setResult)
                modelContext.insert(setResult)
            }
        }

        do {
            try modelContext.save()
            print("Workout result persisted successfully: \(sessionId)")
            return true
        } catch {
            print("Failed to save workout result: \(error)")
            return false
        }
    }
}
