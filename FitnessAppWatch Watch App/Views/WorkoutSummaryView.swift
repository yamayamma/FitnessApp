//
//  WorkoutSummaryView.swift
//  FitnessAppWatch Watch App
//
//  Created for 001-strength-training-system
//  T020: Workout summary with total time, exercise count, total sets (FR-021)
//

import SwiftUI

/// ワークアウト完了サマリー画面（Apple Watch）
struct WorkoutSummaryView: View {
    let viewModel: WorkoutViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // ヘッダー
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)

                Text("ワークアウト完了")
                    .font(.headline)

                // サマリーデータ
                VStack(spacing: 8) {
                    // 合計時間
                    self.summaryRow(
                        icon: "timer",
                        label: "合計時間",
                        value: self.viewModel.elapsedTimeString
                    )

                    // 種目数
                    self.summaryRow(
                        icon: "figure.strengthtraining.traditional",
                        label: "種目数",
                        value: "\(self.viewModel.completedExerciseCount)"
                    )

                    // 総セット数
                    self.summaryRow(
                        icon: "repeat",
                        label: "総セット数",
                        value: "\(self.viewModel.completedTotalSets)"
                    )

                    // メニュー名（メニューベースの場合）
                    if let menuName = viewModel.currentSession?.menuName {
                        self.summaryRow(
                            icon: "list.clipboard",
                            label: "メニュー",
                            value: menuName
                        )
                    }
                }
                .padding(.vertical, 4)

                // 「閉じる」ボタン → メニュー一覧に戻る (FR-021)
                Button("閉じる") {
                    // NavigationStackのルートに戻る
                    self.dismiss()
                }
                .tint(.blue)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helper Views

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
