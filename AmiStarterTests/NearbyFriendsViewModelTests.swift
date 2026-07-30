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
        let viewModel = NearbyFriendsViewModel(friendService: service)

        await viewModel.loadFriends()

        #expect(viewModel.friends == expectedFriends)
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
        let viewModel = NearbyFriendsViewModel(friendService: service, now: { now })

        await viewModel.loadFriends()

        let annotations = viewModel.friendAnnotations
        #expect(annotations.first?.isStale == false)
        #expect(annotations.first?.displayName == "Ada Chen")
        #expect(annotations.first?.systemImageName == "person.fill")
        #expect(annotations.last?.isStale == true)
        #expect(annotations.last?.displayName == "Sam Okafor (Stale)")
        #expect(annotations.last?.systemImageName == "clock.badge.exclamationmark")
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
