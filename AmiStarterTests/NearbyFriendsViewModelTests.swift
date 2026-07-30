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
