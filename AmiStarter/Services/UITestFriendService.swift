import CoreLocation
import Foundation

@MainActor
struct UITestFriendService: FriendServiceProtocol {
    let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    func friendSnapshots() -> AsyncStream<[Friend]> {
        AsyncStream { continuation in
            let now = Date(timeIntervalSince1970: 1_800)

            continuation.yield([
                Friend(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
                    displayName: "Ada Chen",
                    coordinate: CLLocationCoordinate2D(latitude: 37.7761, longitude: -122.4203),
                    lastUpdated: now.addingTimeInterval(-60)
                ),
                Friend(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
                    displayName: "Sam Okafor",
                    coordinate: CLLocationCoordinate2D(latitude: 37.7708, longitude: -122.4227),
                    lastUpdated: now.addingTimeInterval(-(31 * 60))
                ),
                Friend(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000103")!,
                    displayName: "Dana Lee",
                    coordinate: CLLocationCoordinate2D(latitude: 37.7839, longitude: -122.4114),
                    lastUpdated: now.addingTimeInterval(-120)
                )
            ])
            continuation.finish()
        }
    }
}
