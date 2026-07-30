import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class NearbyFriendsViewModel {
    private(set) var friends: [Friend] = []

    let userLocation: CLLocationCoordinate2D
    let initialRegion: MKCoordinateRegion

    private let friendService: FriendServiceProtocol

    convenience init() {
        self.init(friendService: MockFriendService())
    }

    init(friendService: FriendServiceProtocol) {
        self.friendService = friendService
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
