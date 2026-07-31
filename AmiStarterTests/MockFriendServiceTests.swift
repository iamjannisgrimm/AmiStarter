import CoreLocation
import Testing
@testable import AmiStarter

@MainActor
struct MockFriendServiceTests {
    @Test func seedIncludesFreshStaleAndIncomingNearbyCases() {
        let seed = MockFriendService.seed
        let names = Set(seed.map(\.displayName))

        #expect(seed.count == 6)
        #expect(names.contains("Ada Chen"))
        #expect(names.contains("Sam Okafor"))
        #expect(names.contains("Dana Lee"))

        let staleFriends = seed.filter { $0.lastUpdated.timeIntervalSinceNow <= -(30 * 60) }
        #expect(staleFriends.contains { $0.displayName == "Sam Okafor" })
        #expect(staleFriends.contains { $0.displayName == "Lena Fisch" })
    }

    @Test func userLocationMatchesDocumentedCurrentUserLocation() {
        let service = MockFriendService()

        #expect(service.userLocation.latitude == MockFriendService.currentUserLocation.latitude)
        #expect(service.userLocation.longitude == MockFriendService.currentUserLocation.longitude)
        #expect(service.userLocation.latitude == 37.7749)
        #expect(service.userLocation.longitude == -122.4194)
    }

    @Test func friendSnapshotsImmediatelyYieldsSeedSnapshot() async {
        let service = MockFriendService()
        var iterator = service.friendSnapshots().makeAsyncIterator()

        let snapshot = await iterator.next()
        service.stop()

        #expect(snapshot?.count == MockFriendService.seed.count)
        #expect(snapshot?.map(\.displayName) == MockFriendService.seed.map(\.displayName))
    }

    @Test func uiTestFriendServiceYieldsDeterministicSnapshotAndFinishes() async {
        let service = UITestFriendService()
        var iterator = service.friendSnapshots().makeAsyncIterator()

        let firstSnapshot = await iterator.next()
        let secondSnapshot = await iterator.next()

        #expect(firstSnapshot?.map(\.displayName) == ["Ada Chen", "Sam Okafor", "Dana Lee"])
        #expect(secondSnapshot == nil)
    }
}
