//
//  HistoryListView.swift
//  FitnessApp
//
//  Created for 001-strength-training-system
//  T029: History list with today's workouts at top, past workouts below (FR-008, FR-010)
//

import SwiftUI
import SwiftData

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
                        value: "\(viewModel.totalWorkouts)",
                        icon: "figure.strengthtraining.traditional"
                    )
                    StatCard(
                        title: "合計時間",
                        value: viewModel.totalDurationString,
                        icon: "timer"
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // 当日のワークアウト
            if !viewModel.todaysSessions.isEmpty {
                Section("今日") {
                    ForEach(viewModel.todaysSessions, id: \.id) { session in
                        NavigationLink {
                            WorkoutDetailView(session: session)
                        } label: {
                            WorkoutSessionRow(session: session)
                        }
                    }
                }
            }
            
            // 過去のワークアウト
            if !viewModel.pastSessions.isEmpty {
                Section("過去の記録") {
                    ForEach(viewModel.pastSessions, id: \.id) { session in
                        NavigationLink {
                            WorkoutDetailView(session: session)
                        } label: {
                            WorkoutSessionRow(session: session)
                        }
                    }
                }
            }
            
            // データ無し
            if viewModel.workoutSessions.isEmpty {
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
            viewModel.loadSessions(modelContext: modelContext)
        }
        .refreshable {
            viewModel.loadSessions(modelContext: modelContext)
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
            Text(session.menuName ?? "フリーワークアウト")
                .font(.headline)
            
            HStack(spacing: 12) {
                // 日付
                Label(
                    HistoryViewModel.formatDate(session.startDate),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                
                // 時間
                Label(
                    HistoryViewModel.formatDuration(session.totalDuration),
                    systemImage: "timer"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            // 種目数
            Text("\(session.exerciseResults.count)種目")
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
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
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
