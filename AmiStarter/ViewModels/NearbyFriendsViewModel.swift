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
    private(set) var feedState: FriendFeedState = .loading
    private(set) var hiddenInvalidLocationCount = 0
    private(set) var notificationsAreUnavailable = false

    var statusMessage: FriendFeedStatusMessage? {
        if hiddenInvalidLocationCount > 0 {
            return FriendFeedStatusMessage(
                title: "Some locations were hidden",
                message: Self.hiddenLocationMessage(count: hiddenInvalidLocationCount),
                systemImageName: "location.slash"
            )
        }

        switch feedState {
        case .loading:
            return FriendFeedStatusMessage(
                title: "Loading friends",
                message: "Checking recent locations...",
                systemImageName: "location.magnifyingglass"
            )
        case .empty:
            return FriendFeedStatusMessage(
                title: "No friends to show",
                message: "No recent friend location data is available right now.",
                systemImageName: "person.2.slash"
            )
        case .failed(let message):
            return FriendFeedStatusMessage(
                title: "Unable to load friends",
                message: message,
                systemImageName: "exclamationmark.triangle"
            )
        case .ready:
            if notificationsAreUnavailable {
                return FriendFeedStatusMessage(
                    title: "Nearby alerts are off",
                    message: "You can still view friends on the map.",
                    systemImageName: "bell.slash"
                )
            }

            return nil
        }
    }

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
        feedState = .loading
        friends = []
        hiddenInvalidLocationCount = 0
        notificationsAreUnavailable = false
        followedFriendID = nil
        hasObservedInitialSnapshot = false
        nearbyFriendIDs = []

        let canNotify = await notificationService.requestAuthorization()
        notificationsAreUnavailable = !canNotify

        do {
            for try await snapshot in friendService.friendSnapshots() {
                await handleSnapshot(snapshot, canNotify: canNotify)
            }

            if !hasObservedInitialSnapshot {
                feedState = .empty
            }
        } catch is CancellationError {
            return
        } catch {
            friends = []
            hiddenInvalidLocationCount = 0
            feedState = .failed(Self.errorMessage(for: error))
        }
    }

    func followFriend(id: Friend.ID) {
        guard friends.contains(where: { $0.id == id }) else { return }

        followedFriendID = id
    }

    func stopFollowing() {
        followedFriendID = nil
    }

    private func handleSnapshot(
        _ snapshot: [Friend],
        canNotify: Bool
    ) async {
        let validFriends = snapshot.filter { CLLocationCoordinate2DIsValid($0.coordinate) }
        hiddenInvalidLocationCount = snapshot.count - validFriends.count

        let nearbyFriends = validFriends.filter(isNearby)
        let nearbyIDs = Set(nearbyFriends.map(\.id))
        let newlyNearbyFriends = nearbyFriends.filter { !nearbyFriendIDs.contains($0.id) }

        friends = validFriends
        nearbyFriendIDs = nearbyIDs
        feedState = validFriends.isEmpty ? .empty : .ready

        if let followedFriendID, !validFriends.contains(where: { $0.id == followedFriendID }) {
            stopFollowing()
        }

        guard hasObservedInitialSnapshot else {
            // Friends already nearby at launch establish the baseline; only later
            // outside-to-inside transitions should interrupt the user.
            hasObservedInitialSnapshot = true
            return
        }

        if canNotify, !newlyNearbyFriends.isEmpty {
            do {
                try await notificationService.notifyNearbyFriends(newlyNearbyFriends)
                notificationsAreUnavailable = false
            } catch is CancellationError {
                return
            } catch {
                notificationsAreUnavailable = true
            }
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

    private static func errorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let errorDescription = localizedError.errorDescription {
            return errorDescription
        }

        return "Please try again in a moment."
    }

    private static func hiddenLocationMessage(count: Int) -> String {
        if count == 1 {
            return "1 friend location could not be shown."
        }

        return "\(count) friend locations could not be shown."
    }
}

enum FriendFeedState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
}

struct FriendFeedStatusMessage: Equatable {
    let title: String
    let message: String
    let systemImageName: String
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
