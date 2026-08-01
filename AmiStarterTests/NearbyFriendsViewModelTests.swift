import CoreLocation
import MapKit
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
        #expect(viewModel.feedState == .ready)
        #expect(viewModel.statusMessage == nil)
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

    @Test func loadFriendsNotifiesWithinFiveHundredMetersNotFeet() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let farFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let withinFiveHundredMetersButOutsideFiveHundredFeetFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: coordinate(from: userLocation, metersNorth: 300),
            lastUpdated: Date(timeIntervalSince1970: 1_900)
        )
        let service = MockFriendStreamService(
            userLocation: userLocation,
            snapshots: [[farFriend], [withinFiveHundredMetersButOutsideFiveHundredFeetFriend]]
        )
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.notifiedFriendGroups == [[withinFiveHundredMetersButOutsideFiveHundredFeetFriend]])
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

    @Test func initialRegionCentersOnCurrentUserLocation() {
        let service = MockFriendStreamService(snapshots: [])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        #expect(viewModel.userLocation.latitude == service.userLocation.latitude)
        #expect(viewModel.userLocation.longitude == service.userLocation.longitude)
        #expect(viewModel.initialRegion.center.latitude == service.userLocation.latitude)
        #expect(viewModel.initialRegion.center.longitude == service.userLocation.longitude)
    }

    @Test func friendAnnotationsTreatExactlyThirtyMinutesAsFresh() async {
        let now = Date(timeIntervalSince1970: 3_600)
        let boundaryFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: now.addingTimeInterval(-30 * 60)
        )
        let service = MockFriendStreamService(snapshots: [[boundaryFriend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService(),
            now: { now }
        )

        await viewModel.loadFriends()

        #expect(viewModel.friendAnnotations.first?.isStale == false)
        #expect(viewModel.friendAnnotations.first?.displayName == "Ada Chen")
    }

    @Test func loadFriendsDoesNotNotifyWhenAuthorizationIsDenied() async {
        let farFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let nearbyFriend = Friend(
            id: farFriend.id,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4196),
            lastUpdated: Date(timeIntervalSince1970: 1_900)
        )
        let service = MockFriendStreamService(snapshots: [[farFriend], [nearbyFriend]])
        let notificationService = MockNearbyFriendNotificationService(authorizationResult: false)
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.authorizationRequestCount == 1)
        #expect(notificationService.notifiedFriendGroups.isEmpty)
    }

    @Test func loadFriendsDoesNotRepeatNotifyWhileFriendRemainsNearby() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let farFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let firstNearbyFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4196),
            lastUpdated: Date(timeIntervalSince1970: 1_900)
        )
        let secondNearbyFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4197),
            lastUpdated: Date(timeIntervalSince1970: 2_000)
        )
        let service = MockFriendStreamService(snapshots: [[farFriend], [firstNearbyFriend], [secondNearbyFriend]])
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.notifiedFriendGroups == [[firstNearbyFriend]])
    }

    @Test func loadFriendsNotifiesAgainWhenFriendLeavesAndReentersNearbyRadius() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let farFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let firstNearbyFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4196),
            lastUpdated: Date(timeIntervalSince1970: 1_900)
        )
        let secondNearbyFriend = Friend(
            id: friendID,
            displayName: "Dana Lee",
            coordinate: CLLocationCoordinate2D(latitude: 37.7753, longitude: -122.4197),
            lastUpdated: Date(timeIntervalSince1970: 2_100)
        )
        let service = MockFriendStreamService(snapshots: [
            [farFriend],
            [firstNearbyFriend],
            [farFriend],
            [secondNearbyFriend]
        ])
        let notificationService = MockNearbyFriendNotificationService()
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(notificationService.notifiedFriendGroups == [[firstNearbyFriend], [secondNearbyFriend]])
    }

    @Test func loadFriendsShowsEmptyStateWhenSnapshotHasNoFriends() async {
        let service = MockFriendStreamService(snapshots: [[]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends.isEmpty)
        #expect(viewModel.feedState == .empty)
        #expect(viewModel.statusMessage?.title == "No friends to show")
    }

    @Test func loadFriendsShowsEmptyStateWhenStreamFinishesWithoutAnySnapshots() async {
        let service = MockFriendStreamService(snapshots: [])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends.isEmpty)
        #expect(viewModel.feedState == .empty)
        #expect(viewModel.statusMessage?.systemImageName == "person.2.slash")
    }

    @Test func loadFriendsShowsFailureStateWhenServiceThrows() async {
        let service = MockFriendStreamService(
            snapshots: [],
            failure: FriendStreamTestError.unavailable
        )
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends.isEmpty)
        #expect(viewModel.feedState == .failed("Friend location data is unavailable."))
        #expect(viewModel.statusMessage?.title == "Unable to load friends")
        #expect(viewModel.statusMessage?.message == "Friend location data is unavailable.")
    }

    @Test func cancellationPreservesTheLatestLoadedSnapshot() async {
        let friend = Friend(
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(
            snapshots: [[friend]],
            failure: CancellationError()
        )
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends == [friend])
        #expect(viewModel.feedState == .ready)
        #expect(viewModel.statusMessage == nil)
    }

    @Test func loadFriendsHidesInvalidCoordinatesAndShowsWarning() async {
        let validFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let invalidFriend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            displayName: "Invalid Friend",
            coordinate: CLLocationCoordinate2D(latitude: 200, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(snapshots: [[validFriend, invalidFriend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends == [validFriend])
        #expect(viewModel.hiddenInvalidLocationCount == 1)
        #expect(viewModel.feedState == .ready)
        #expect(viewModel.statusMessage?.title == "Some locations were hidden")
    }

    @Test func loadFriendsShowsInvalidLocationWarningWhenEveryLocationIsInvalid() async {
        let invalidFriends = [
            Friend(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                displayName: "Invalid One",
                coordinate: CLLocationCoordinate2D(latitude: 200, longitude: -122.4203),
                lastUpdated: Date(timeIntervalSince1970: 1_800)
            ),
            Friend(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                displayName: "Invalid Two",
                coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -200),
                lastUpdated: Date(timeIntervalSince1970: 1_800)
            )
        ]
        let service = MockFriendStreamService(snapshots: [invalidFriends])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends.isEmpty)
        #expect(viewModel.hiddenInvalidLocationCount == 2)
        #expect(viewModel.feedState == .empty)
        #expect(viewModel.statusMessage?.title == "Some locations were hidden")
        #expect(viewModel.statusMessage?.message == "2 friend locations could not be shown.")
    }

    @Test func loadFriendsShowsNotificationUnavailableWarningWhenAuthorizationIsDeniedAndDataLoads() async {
        let friend = Friend(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(snapshots: [[friend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService(authorizationResult: false)
        )

        await viewModel.loadFriends()

        #expect(viewModel.notificationsAreUnavailable)
        #expect(viewModel.feedState == .ready)
        #expect(viewModel.statusMessage?.title == "Nearby alerts are off")
    }

    @Test func loadFriendsShowsNotificationUnavailableWarningWhenSchedulingFails() async {
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
        let notificationService = MockNearbyFriendNotificationService(
            notificationError: NotificationTestError.schedulingFailed
        )
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: notificationService
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends == [nearbyFriend])
        #expect(viewModel.feedState == .ready)
        #expect(viewModel.notificationsAreUnavailable)
        #expect(viewModel.statusMessage?.title == "Nearby alerts are off")
    }

    @Test func followFriendStoresSelectedFriendAndRegion() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let friend = Friend(
            id: friendID,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(snapshots: [[friend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()
        viewModel.followFriend(id: friendID)

        #expect(viewModel.followedFriendID == friendID)
        #expect(viewModel.followedFriend == friend)
        #expect(viewModel.followedFriendRegion?.center.latitude == friend.coordinate.latitude)
        #expect(viewModel.followedFriendRegion?.center.longitude == friend.coordinate.longitude)
    }

    @Test func followedFriendRegionUpdatesAsFriendLocationChanges() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let firstLocation = Friend(
            id: friendID,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let updatedLocation = Friend(
            id: friendID,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7780, longitude: -122.4210),
            lastUpdated: Date(timeIntervalSince1970: 1_900)
        )
        let service = ControlledFriendStreamService(initialSnapshot: [firstLocation])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        let loadTask = Task {
            await viewModel.loadFriends()
        }

        let didLoadInitialSnapshot = await waitUntil { viewModel.friends == [firstLocation] }
        #expect(didLoadInitialSnapshot)

        viewModel.followFriend(id: friendID)
        service.yield([updatedLocation])
        service.finish()
        await loadTask.value

        #expect(viewModel.followedFriend == updatedLocation)
        #expect(viewModel.followedFriendRegion?.center.latitude == updatedLocation.coordinate.latitude)
        #expect(viewModel.followedFriendRegion?.center.longitude == updatedLocation.coordinate.longitude)
    }

    @Test func stopFollowingClearsSelectedFriend() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let friend = Friend(
            id: friendID,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(snapshots: [[friend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()
        viewModel.followFriend(id: friendID)
        viewModel.stopFollowing()

        #expect(viewModel.followedFriendID == nil)
        #expect(viewModel.followedFriend == nil)
        #expect(viewModel.followedFriendRegion == nil)
    }

    @Test func followFriendIgnoresUnknownFriendID() async {
        let friend = Friend(
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = MockFriendStreamService(snapshots: [[friend]])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        await viewModel.loadFriends()
        viewModel.followFriend(id: UUID())

        #expect(viewModel.followedFriendID == nil)
        #expect(viewModel.followedFriend == nil)
    }

    @Test func loadFriendsClearsFollowedFriendWhenFriendDisappears() async {
        let friendID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let friend = Friend(
            id: friendID,
            displayName: "Ada Chen",
            coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
            lastUpdated: Date(timeIntervalSince1970: 1_800)
        )
        let service = ControlledFriendStreamService(initialSnapshot: [friend])
        let viewModel = NearbyFriendsViewModel(
            friendService: service,
            notificationService: MockNearbyFriendNotificationService()
        )

        let loadTask = Task {
            await viewModel.loadFriends()
        }

        let didLoadInitialSnapshot = await waitUntil { viewModel.friends == [friend] }
        #expect(didLoadInitialSnapshot)

        viewModel.followFriend(id: friendID)
        service.yield([])
        service.finish()
        await loadTask.value

        #expect(viewModel.followedFriendID == nil)
        #expect(viewModel.followedFriend == nil)
    }
}

private final class MockFriendStreamService: FriendServiceProtocol {
    let userLocation: CLLocationCoordinate2D

    private let snapshots: [[Friend]]
    private let failure: Error?

    init(
        userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        snapshots: [[Friend]],
        failure: Error? = nil
    ) {
        self.userLocation = userLocation
        self.snapshots = snapshots
        self.failure = failure
    }

    func friendSnapshots() -> AsyncThrowingStream<[Friend], Error> {
        AsyncThrowingStream { continuation in
            for snapshot in snapshots {
                continuation.yield(snapshot)
            }

            if let failure {
                continuation.finish(throwing: failure)
            } else {
                continuation.finish()
            }
        }
    }
}

private final class MockNearbyFriendNotificationService: NearbyFriendNotificationScheduling {
    private(set) var authorizationRequestCount = 0
    private(set) var notifiedFriendGroups: [[Friend]] = []

    private let authorizationResult: Bool
    private let notificationError: Error?

    init(
        authorizationResult: Bool = true,
        notificationError: Error? = nil
    ) {
        self.authorizationResult = authorizationResult
        self.notificationError = notificationError
    }

    func requestAuthorization() async -> Bool {
        authorizationRequestCount += 1
        return authorizationResult
    }

    func notifyNearbyFriends(_ friends: [Friend]) async throws {
        if let notificationError {
            throw notificationError
        }

        notifiedFriendGroups.append(friends)
    }
}

private final class ControlledFriendStreamService: FriendServiceProtocol {
    let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    private let stream: AsyncThrowingStream<[Friend], Error>
    private let continuation: AsyncThrowingStream<[Friend], Error>.Continuation

    init(initialSnapshot: [Friend]) {
        var capturedContinuation: AsyncThrowingStream<[Friend], Error>.Continuation?
        stream = AsyncThrowingStream { continuation in
            capturedContinuation = continuation
        }
        continuation = capturedContinuation!
        continuation.yield(initialSnapshot)
    }

    func friendSnapshots() -> AsyncThrowingStream<[Friend], Error> {
        stream
    }

    func yield(_ snapshot: [Friend]) {
        continuation.yield(snapshot)
    }

    func finish() {
        continuation.finish()
    }
}

private enum FriendStreamTestError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Friend location data is unavailable."
    }
}

private enum NotificationTestError: Error {
    case schedulingFailed
}

private func coordinate(
    from coordinate: CLLocationCoordinate2D,
    metersNorth: CLLocationDistance
) -> CLLocationCoordinate2D {
    CLLocationCoordinate2D(
        latitude: coordinate.latitude + metersNorth / 111_000,
        longitude: coordinate.longitude
    )
}

private func waitUntil(
    maxAttempts: Int = 1_000,
    condition: () -> Bool
) async -> Bool {
    for _ in 0..<maxAttempts {
        if condition() {
            return true
        }

        await Task.yield()
    }

    return condition()
}
