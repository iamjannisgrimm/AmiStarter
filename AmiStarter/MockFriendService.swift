import CoreLocation
import Foundation

/// Mock data source for the Nearby Friends exercise.
///
/// You get two ways to consume this — pick whichever fits the approach you
/// choose. This type intentionally does **not** decide your reactivity model for
/// you; that choice is yours to make and defend.
///
/// 1. Static snapshot — ignore the live feed entirely:
///
///        let friends = MockFriendService.seed
///
/// 2. Live feed — a fresh `[Friend]` snapshot roughly every 2 seconds via a plain
///    callback. Wrap it however you like:
///        • Swift Concurrency — bridge it into an `AsyncStream`
///        • Combine — forward it through a `PassthroughSubject`
///        • or just observe the callback directly
///
///        let service = MockFriendService()
///        service.start { friends in /* ... */ }
///        // later: service.stop()
///
/// What the feed does (so the requirements are actually exercisable):
///   • The seed includes friends whose `lastUpdated` is already older than 30
///     minutes, so the stale case is present from the very first snapshot.
///   • Fresh friends drift slightly and have their timestamps refreshed each tick.
///   • A few seconds in, one friend ("Dana Lee") moves close to
///     `currentUserLocation` — a clear "a new nearby friend appeared" moment.
final class MockFriendService {
    /// A reasonable "you are here" reference point (downtown San Francisco). Use
    /// it as the origin for proximity — or swap in Core Location if you prefer.
    static let currentUserLocation = CLLocationCoordinate2D(
        latitude: 37.7749,
        longitude: -122.4194
    )

    /// One-shot snapshot, for a static / hardcoded approach.
    static var seed: [Friend] { makeSeed() }

    private var task: Task<Void, Never>?

    /// Begin emitting snapshots. `onUpdate` is called on the main actor with the
    /// latest set of friends, starting immediately and then roughly every 2
    /// seconds. Call `stop()` when you're done.
    @MainActor
    func start(onUpdate: @escaping ([Friend]) -> Void) {
        stop()
        task = Task { @MainActor in
            var friends = MockFriendService.makeSeed()
            onUpdate(friends)

            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                tick += 1
                friends = MockFriendService.advance(friends, tick: tick)
                onUpdate(friends)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    // MARK: - Mock data

    private static func makeSeed() -> [Friend] {
        let now = Date()
        func ago(_ minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        func offset(_ dLat: Double, _ dLng: Double) -> CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: currentUserLocation.latitude + dLat,
                longitude: currentUserLocation.longitude + dLng
            )
        }

        return [
            Friend(displayName: "Ada Chen", coordinate: offset(0.0012, -0.0009), lastUpdated: ago(1)),
            Friend(displayName: "Marco Diaz", coordinate: offset(-0.0020, 0.0016), lastUpdated: ago(4)),
            Friend(displayName: "Priya Nair", coordinate: offset(0.0031, 0.0028), lastUpdated: ago(12)),
            // Already stale (> 30 min) at launch.
            Friend(displayName: "Sam Okafor", coordinate: offset(-0.0041, -0.0033), lastUpdated: ago(48)),
            Friend(displayName: "Lena Fisch", coordinate: offset(0.0052, -0.0047), lastUpdated: ago(92)),
            // Starts far away + fresh; walks in on tick 3 (see `advance`).
            Friend(displayName: "Dana Lee", coordinate: offset(0.0090, 0.0080), lastUpdated: ago(2)),
        ]
    }

    private static func advance(_ input: [Friend], tick: Int) -> [Friend] {
        var friends = input
        let staleThreshold: TimeInterval = 30 * 60

        for i in friends.indices {
            // Keep already-fresh friends "alive": nudge position + refresh time.
            if friends[i].lastUpdated.timeIntervalSinceNow > -staleThreshold {
                friends[i].coordinate.latitude += .random(in: -0.0006...0.0006)
                friends[i].coordinate.longitude += .random(in: -0.0006...0.0006)
                friends[i].lastUpdated = Date()
            }
        }

        // The "new nearby friend" moment.
        if tick == 3, let dana = friends.firstIndex(where: { $0.displayName == "Dana Lee" }) {
            friends[dana].coordinate = CLLocationCoordinate2D(
                latitude: currentUserLocation.latitude + 0.0018,
                longitude: currentUserLocation.longitude + 0.0011
            )
            friends[dana].lastUpdated = Date()
        }

        return friends
    }
}
