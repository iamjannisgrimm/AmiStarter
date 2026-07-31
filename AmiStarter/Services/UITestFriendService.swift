import CoreLocation
import Foundation

@MainActor
struct UITestFriendService: FriendServiceProtocol {
    enum Scenario {
        case populated
        case empty
        case failure
    }

    let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    private let scenario: Scenario

    init(scenario: Scenario = .populated) {
        self.scenario = scenario
    }

    func friendSnapshots() -> AsyncThrowingStream<[Friend], Error> {
        AsyncThrowingStream { continuation in
            switch scenario {
            case .populated:
                continuation.yield(Self.friends())
                continuation.finish()
            case .empty:
                continuation.yield([])
                continuation.finish()
            case .failure:
                continuation.finish(throwing: UITestFriendServiceError.unavailable)
            }
        }
    }

    private static func friends() -> [Friend] {
        let now = Date(timeIntervalSince1970: 1_800)

        return [
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
        ]
    }
}

private enum UITestFriendServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Friend location data is unavailable."
    }
}
