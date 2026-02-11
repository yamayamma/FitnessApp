import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some View {
        VStack {
            Text("Selected")
                .font(.caption)

            Text(sessionManager.receivedWorkout)
                .font(.headline)
        }
    }
}
#Preview {
    ContentView()
}
