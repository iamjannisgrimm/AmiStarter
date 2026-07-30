import CoreLocation

@MainActor
protocol FriendServiceProtocol {
    var userLocation: CLLocationCoordinate2D { get }

    func friendSnapshots() -> AsyncStream<[Friend]>
}
