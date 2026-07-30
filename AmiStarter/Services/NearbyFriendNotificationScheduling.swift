import Foundation

@MainActor
protocol NearbyFriendNotificationScheduling {
    func requestAuthorization() async -> Bool
    func notifyNearbyFriends(_ friends: [Friend]) async
}

struct NoopNearbyFriendNotificationService: NearbyFriendNotificationScheduling {
    func requestAuthorization() async -> Bool {
        false
    }

    func notifyNearbyFriends(_ friends: [Friend]) async {}
}
