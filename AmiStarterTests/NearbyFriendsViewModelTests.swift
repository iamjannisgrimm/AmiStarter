import CoreLocation
import Testing
@testable import AmiStarter

@MainActor
struct NearbyFriendsViewModelTests {
    @Test func loadFriendsUpdatesFriendsFromServiceStream() async {
        let expectedFriends = [
            Friend(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                displayName: "Ada Chen",
                coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
                lastUpdated: Date(timeIntervalSince1970: 1_800)
            )
        ]
        let service = MockFriendStreamService(snapshots: [expectedFriends])
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends == expectedFriends)
        #expect(notificationService.authorizationRequestCount == 1)
    }

    @Test func friendAnnotationsMarkLocationsOlderThanThirtyMinutesAsStale() async {
        let now = Date(timeIntervalSince1970: 3_600)
        let freshFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: now.addingTimeInterval(-29 * 60)
        )
        let staleFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            displayName: "Sam Okafor",
            coordinate: CLLocationCoordinate2D(latitude: 37.7708, longitude: -122.4227),
            lastUpdated: now.addingTimeInterval(-31 * 60)
        )
        let service = MockFriendStreamService(snapshots: [[freshFriend, staleFriend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService(),
            now: { now }
        )

        await viewModel.loadFriends()

        let annotations = viewModel.friendAnnotations
        #expect(annotations.first?.isStale == false)
        #expect(annotations.first?.displayName == "Ada Chen")
        #expect(annotations.first?.systemImageName == "person.fill")
        #expect(annotations.last?.isStale == true)
        #expect(annotations.last?.displayName == "Sam Okafor (Stale)")
        #expect(annotations.last?.systemImageName == "clock.badge.exclamationmark")
    }

    @Test func loadFriendsDoesNotNotifyForInitiallyNearbyFriends() async {
        let nearbyFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4196),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(snapshots: [[nearbyFriend]])
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.notifiedFriendGroups.isEmpty)
    }

    @Test func loadFriendsNotifiesWhenFriendBecomesNearby() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let farFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let nearbyFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4196),
            lastUpdated: Date(timeIntervalSince1970: 1_900)
        )
        let service = MockFriendStreamService(snapshots: [[farFriend], [nearbyFriend]])
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.notifiedFriendGroups.count == 1)
        #expect(notificationService.notifiedFriendGroups.first == [nearbyFriend])
    }

    @Test func loadFriendsGroupsFriendsThatBecomeNearbyTogether() async {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let farFriends = [
            Friend(
                id: firstID,
                displayName: "Dana Lee",
                coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
                lastUpdated: Date(timeIntervalSince1970: 1_800)
            ),
            Friend(
                id: secondID,
                displayName: "Marco Diaz",
                coordinate: CLLocationCoordinate2D(latitude: 37.7844, longitude: -122.4108),
                lastUpdated: Date(timeIntervalSince1970: 1_800)
            )
        ]
        let nearbyFriends = [
            Friend(
                id: firstID,
                displayName: "Dana Lee",
                coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4196),
                lastUpdated: Date(timeIntervalSince1970: 1_900)
            ),
            Friend(
                id: secondID,
                displayName: "Marco Diaz",
                coordinate: CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4198),
                lastUpdated: Date(timeIntervalSince1970: 1_900)
            )
        ]
        let service = MockFriendStreamService(snapshots: [farFriends, nearbyFriends])
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.notifiedFriendGroups.count == 1)
        #expect(notificationService.notifiedFriendGroups.first == nearbyFriends)
    }
}

private final class MockFriendStreamService: FriendServiceProtocol {
    let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    private let snapshots: [[Friend]]

    init(snapshots: [[Friend]]) {
        self.snapshots = snapshots
    }

    func friendSnapshots() -> AsyncStream<[Friend]> {
        AsyncStream { continuation in
            for snapshot in snapshots {
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
    }
}

private final class MockNearbyFriendNotificationService: NearbyFriendNotificationScheduling {
    private(set) var authorizationRequestCount = 0
    private(set) var notifiedFriendGroups: [[Friend]] = []

    func requestAuthorization() async -> Bool {
        authorizationRequestCount += 1
        return true
    }

    func notifyNearbyFriends(_ friends: [Friend]) async {
        notifiedFriendGroups.append(friends)
    }
}
