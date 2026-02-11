import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    override private init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // 必須 delegate（中身は空でOK）
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // データ送信
    func sendWorkoutName(_ name: String) {
        WCSession.default.sendMessage(
            ["workout": name],
            replyHandler: nil
        )
    }
}
