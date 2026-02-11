import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Send to Watch") {
                VStack(spacing: 16) {
                    Button("Send Push Day") {
                        WatchConnectivityManager.shared.sendWorkoutName("Push Day")
                    }

                    Button("Send Pull Day") {
                        WatchConnectivityManager.shared.sendWorkoutName("Pull Day")
                    }
                }
                .navigationTitle("Send")
            }
        }
    }
}

#Preview {
    ContentView()
}
