//
//  HistoryViewModel.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T028: History view model with filtered WorkoutSessions and statistics
//

import Foundation
import SwiftData

/// ワークアウト履歴管理のViewModel（iPhone側）
@Observable
final class HistoryViewModel {
    
    /// ワークアウト履歴一覧（completedのみ、日付降順）
    var workoutSessions: [WorkoutSession] = []
    
    /// 当日のワークアウト
    var todaysSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return workoutSessions.filter { calendar.isDate($0.startDate, inSameDayAs: today) }
    }
    
    /// 過去のワークアウト（当日除く）
    var pastSessions: [WorkoutSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return workoutSessions.filter { !calendar.isDate($0.startDate, inSameDayAs: today) }
    }
    
    /// 基本統計: 合計ワークアウト時間
    var totalDuration: TimeInterval {
        workoutSessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    /// 基本統計: 合計ワークアウト数
    var totalWorkouts: Int {
        workoutSessions.count
    }
    
    /// 合計時間の表示文字列
    var totalDurationString: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
    
    // MARK: - Data Loading
    
    /// 履歴データを読み込み（completedのみ、日付降順）
    func loadSessions(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.statusRawValue == "completed"
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            workoutSessions = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch workout sessions: \(error)")
            workoutSessions = []
        }
    }
    
    // MARK: - Formatting Helpers
    
    /// ワークアウトの日付表示
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    /// ワークアウトの時間表示
    static func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
