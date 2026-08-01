import UserNotifications

final class NearbyFriendNotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NearbyFriendNotificationPresentationDelegate()

    let presentationOptions: UNNotificationPresentationOptions = [.banner, .list, .sound, .badge]

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        presentationOptions
    }
}
