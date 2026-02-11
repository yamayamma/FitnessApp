import WatchConnectivity
import SwiftUI
import Combine

final class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    @Published var receivedWorkout: String = "No Workout"

    override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any]
    ) {
        DispatchQueue.main.async {
            if let workout = message["workout"] as? String {
                self.receivedWorkout = workout
            }
        }
    }
}
