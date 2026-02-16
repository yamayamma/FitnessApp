//
//  WorkoutDetailView.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T030: Workout session detail view (FR-009)
//

import SwiftUI

/// ワークアウト詳細画面（iPhone）
struct WorkoutDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            // セッション概要
            Section("概要") {
                DetailRow(label: "メニュー", value: self.session.menuName ?? "フリーワークアウト")
                DetailRow(label: "日時", value: HistoryViewModel.formatDate(self.session.startDate))
                DetailRow(label: "合計時間", value: HistoryViewModel.formatDuration(self.session.totalDuration))
                DetailRow(label: "種目数", value: "\(self.session.exerciseResults.count)")
                DetailRow(
                    label: "総セット数",
                    value: "\(self.session.exerciseResults.reduce(0) { $0 + $1.setResults.count })"
                )
            }

            // 種目ごとの詳細
            let sortedResults = self.session.exerciseResults.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(sortedResults, id: \.id) { exerciseResult in
                Section(exerciseResult.exerciseName) {
                    let sortedSets = exerciseResult.setResults.sorted { $0.setNumber < $1.setNumber }
                    ForEach(sortedSets, id: \.id) { setResult in
                        HStack {
                            Text("セット \(setResult.setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(setResult.weight, specifier: "%.1f") kg")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("×")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(setResult.reps) reps")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(self.label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(self.value)
                .fontWeight(.medium)
        }
    }
}
