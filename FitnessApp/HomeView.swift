import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("ワークアウト履歴") {
                    Text("Coming soon...")
                }
                NavigationLink("メニュー管理") {
                    Text("Coming soon...")
                }
            }
            .navigationTitle("FitnessApp")
        }
    }
}

#Preview {
    HomeView()
}
