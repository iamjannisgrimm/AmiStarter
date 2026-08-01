import Testing
import UserNotifications
@testable import AmiStarter

struct NearbyFriendNotificationPresentationDelegateTests {
    @MainActor
    @Test func foregroundPresentationOptionsShowNearbyFriendNotificationsWhileAppIsOpen() {
        let delegate = NearbyFriendNotificationPresentationDelegate()
        let options = delegate.presentationOptions

        #expect(options.contains(.banner))
        #expect(options.contains(.list))
        #expect(options.contains(.sound))
        #expect(options.contains(.badge))
    }
}
