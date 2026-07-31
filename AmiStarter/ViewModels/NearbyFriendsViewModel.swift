import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class NearbyFriendsViewModel {
    private static let staleLocationAge: TimeInterval = 30 * 60
    private static let nearbyRadiusMeters: CLLocationDistance = 500
    private static let followRegionSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    private(set) var friends: [Friend] = []
    private(set) var followedFriendID: Friend.ID?

    var followedFriend: Friend? {
        guard let followedFriendID else { return nil }

        return friends.first { $0.id == followedFriendID }
    }

    var followedFriendRegion: MKCoordinateRegion? {
        guard let followedFriend else { return nil }

        return MKCoordinateRegion(
            center: followedFriend.coordinate,
            span: Self.followRegionSpan
        )
    }

    var followedFriendMapFocus: FriendMapFocus? {
        guard let followedFriend else { return nil }

        return FriendMapFocus(friend: followedFriend)
    }

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

    func followFriend(id: Friend.ID) {
        followedFriendID = id
    }

    func stopFollowing() {
        followedFriendID = nil
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

        if let followedFriendID, !snapshot.contains(where: { $0.id == followedFriendID }) {
            stopFollowing()
        }

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

    var locationFreshnessLabel: String {
        isStale ? "Stale location" : "Fresh location"
    }

    var coordinate: CLLocationCoordinate2D {
        friend.coordinate
    }
}

struct FriendMapFocus: Equatable {
    let friendID: Friend.ID
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    init(friend: Friend) {
        self.friendID = friend.id
        self.latitude = friend.coordinate.latitude
        self.longitude = friend.coordinate.longitude
    }
}
