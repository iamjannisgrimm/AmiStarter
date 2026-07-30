import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class NearbyFriendsViewModel {
    private static let staleLocationAge: TimeInterval = 30 * 60
    private static let nearbyRadiusMeters: CLLocationDistance = 500

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
    private let notificationService: NearbyFriendNotificationScheduling
    private let now: () -> Date
    private var hasObservedInitialSnapshot = false
    private var nearbyFriendIDs = Set<Friend.ID>()

    convenience init() {
        self.init(
            friendService: MockFriendService(),
            notificationService: LocalNearbyFriendNotificationService()
        )
    }

    init(
        friendService: FriendServiceProtocol,
        notificationService: NearbyFriendNotificationScheduling,
        now: @escaping () -> Date = Date.init
    ) {
        self.friendService = friendService
        self.notificationService = notificationService
        self.now = now
        self.userLocation = friendService.userLocation
        self.initialRegion = MKCoordinateRegion(
            center: friendService.userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    }

    func loadFriends() async {
        let canNotify = await notificationService.requestAuthorization()

        for await snapshot in friendService.friendSnapshots() {
            await handleSnapshot(snapshot, canNotify: canNotify)
        }
    }

    private func handleSnapshot(
        _ snapshot: [Friend],
        canNotify: Bool
    ) async {
        let nearbyFriends = snapshot.filter(isNearby)
        let nearbyIDs = Set(nearbyFriends.map(\.id))
        let newlyNearbyFriends = nearbyFriends.filter { !nearbyFriendIDs.contains($0.id) }

        friends = snapshot
        nearbyFriendIDs = nearbyIDs

        guard hasObservedInitialSnapshot else {
            hasObservedInitialSnapshot = true
            return
        }

        if canNotify, !newlyNearbyFriends.isEmpty {
            await notificationService.notifyNearbyFriends(newlyNearbyFriends)
        }
    }

    private func isNearby(_ friend: Friend) -> Bool {
        let userLocation = CLLocation(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude
        )
        let friendLocation = CLLocation(
            latitude: friend.coordinate.latitude,
            longitude: friend.coordinate.longitude
        )

        return userLocation.distance(from: friendLocation) <= Self.nearbyRadiusMeters
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
