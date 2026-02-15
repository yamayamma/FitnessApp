import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                // US2: 履歴管理
                NavigationLink {
                    HistoryListView()
                } label: {
                    Label("ワークアウト履歴", systemImage: "clock.arrow.circlepath")
                }
                
                // US3: メニュー管理
                NavigationLink {
                    MenuManagementView()
                } label: {
                    Label("メニュー管理", systemImage: "list.clipboard")
                }
            }
            .navigationTitle("FitnessApp")
        }
    }
}

#Preview {
    HomeView()
}
