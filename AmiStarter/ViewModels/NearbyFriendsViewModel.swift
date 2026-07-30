import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class NearbyFriendsViewModel {
    private static let staleLocationAge: TimeInterval = 30 * 60

    private(set) var friends: [Friend] = []

    var friendAnnotations: [FriendMapAnnotation] {
        let now = now()

        return friends.map { friend in
            FriendMapAnnotation(
                friend: friend,
                isStale: now.timeIntervalSince(friend.lastUpdated) > Self.staleLocationAge
            )
        }
    }

    let userLocation: CLLocationCoordinate2D
    let initialRegion: MKCoordinateRegion

    private let friendService: FriendServiceProtocol
    private let now: () -> Date

    convenience init() {
        self.init(friendService: MockFriendService())
    }

    init(
        friendService: FriendServiceProtocol,
        now: @escaping () -> Date = Date.init
    ) {
        self.friendService = friendService
        self.now = now
        self.userLocation = friendService.userLocation
        self.initialRegion = MKCoordinateRegion(
            center: friendService.userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    }

    func loadFriends() async {
        for await snapshot in friendService.friendSnapshots() {
            friends = snapshot
        }
    }
}

struct FriendMapAnnotation: Identifiable, Equatable {
    let friend: Friend
    let isStale: Bool

    var id: Friend.ID {
        friend.id
    }

    var displayName: String {
        isStale ? "\(friend.displayName) (Stale)" : friend.displayName
    }

    var systemImageName: String {
        isStale ? "clock.badge.exclamationmark" : "person.fill"
    }

    var coordinate: CLLocationCoordinate2D {
        friend.coordinate
    }
}
