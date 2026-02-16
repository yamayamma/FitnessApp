//
//  HistoryListView.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T029: History list with today's workouts at top, past workouts below (FR-008, FR-010)
//

import SwiftData
import SwiftUI

/// ワークアウト履歴一覧画面（iPhone）
struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        List {
            // 統計サマリー
            Section {
                HStack {
                    StatCard(
                        title: "ワークアウト数",
                        value: "\(self.viewModel.totalWorkouts)",
                        icon: "figure.strengthtraining.traditional"
                    )
                    StatCard(
                        title: "合計時間",
                        value: self.viewModel.totalDurationString,
                        icon: "timer"
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // 当日のワークアウト
            if !self.viewModel.todaysSessions.isEmpty {
                Section("今日") {
                    ForEach(self.viewModel.todaysSessions, id: \.id) { session in
                        NavigationLink {
                            WorkoutDetailView(session: session)
                        } label: {
                            WorkoutSessionRow(session: session)
                        }
                    }
                }
            }

            // 過去のワークアウト
            if !self.viewModel.pastSessions.isEmpty {
                Section("過去の記録") {
                    ForEach(self.viewModel.pastSessions, id: \.id) { session in
                        NavigationLink {
                            WorkoutDetailView(session: session)
                        } label: {
                            WorkoutSessionRow(session: session)
                        }
                    }
                }
            }

            // データ無し
            if self.viewModel.workoutSessions.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("まだワークアウトの記録がありません")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Apple Watchでワークアウトを開始すると\nここに記録が表示されます")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
        .navigationTitle("ワークアウト履歴")
        .onAppear {
            self.viewModel.loadSessions(modelContext: self.modelContext)
        }
        .refreshable {
            self.viewModel.loadSessions(modelContext: self.modelContext)
        }
    }
}

// MARK: - Subviews

/// ワークアウトセッション行
struct WorkoutSessionRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // メニュー名
            Text(self.session.menuName ?? "フリーワークアウト")
                .font(.headline)

            HStack(spacing: 12) {
                // 日付
                Label(
                    HistoryViewModel.formatDate(self.session.startDate),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                // 時間
                Label(
                    HistoryViewModel.formatDuration(self.session.totalDuration),
                    systemImage: "timer"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // 種目数
            Text("\(self.session.exerciseResults.count)種目")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

/// 統計カード
struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: self.icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(self.value)
                .font(.title3)
                .fontWeight(.bold)
            Text(self.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HistoryListView()
    }
}
