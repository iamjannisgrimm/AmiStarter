import UserNotifications

struct LocalNearbyFriendNotificationService: NearbyFriendNotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter
    private let presentationDelegate: NearbyFriendNotificationPresentationDelegate

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        presentationDelegate: NearbyFriendNotificationPresentationDelegate = .shared
    ) {
        self.notificationCenter = notificationCenter
        self.presentationDelegate = presentationDelegate
        notificationCenter.delegate = presentationDelegate
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func notifyNearbyFriends(_ friends: [Friend]) async {
        guard !friends.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: friends)
        content.body = notificationBody(for: friends)
        content.sound = .default
        content.threadIdentifier = "nearby-friends"

        let request = UNNotificationRequest(
            identifier: "nearby-friends-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await notificationCenter.add(request)
    }

    private func notificationTitle(for friends: [Friend]) -> String {
        if friends.count == 1 {
            return "Nearby friend"
        }

        return "\(friends.count) nearby friends"
    }

    private func notificationBody(for friends: [Friend]) -> String {
        if let friend = friends.first, friends.count == 1 {
            return "\(friend.displayName) is now within 500m."
        }

        let names = friends.map(\.displayName).joined(separator: ", ")
        return "\(names) are now within 500m."
    }
}
