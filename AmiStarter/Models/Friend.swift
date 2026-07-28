import CoreLocation
import Foundation

/// A friend and their last-known location — the raw data you're given.
///
/// How you interpret this is up to you: what counts as "stale", what counts as
/// "nearby", how you render it, and how you model change over time are all part
/// of the exercise. This type deliberately stays out of those decisions.
struct Friend: Identifiable, Equatable {
    let id: UUID
    let displayName: String

    /// The friend's last-known coordinate.
    var coordinate: CLLocationCoordinate2D

    /// When that coordinate was last reported. Compare against `Date()` to decide
    /// how fresh (or stale) it is.
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        coordinate: CLLocationCoordinate2D,
        lastUpdated: Date
    ) {
        self.id = id
        self.displayName = displayName
        self.coordinate = coordinate
        self.lastUpdated = lastUpdated
    }

    // CLLocationCoordinate2D isn't Equatable on its own; compare its fields.
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        lhs.id == rhs.id
            && lhs.displayName == rhs.displayName
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.lastUpdated == rhs.lastUpdated
    }
}
