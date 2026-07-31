import XCTest

@MainActor
final class AmiStarterUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLaunchShowsMapAndFriendListButton() {
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["friends-map"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["friends-list-button"].exists)
    }

    func testFriendListShowsFreshAndStaleLocationStates() {
        app.launch()
        openFriendList()

        XCTAssertTrue(app.buttons["friend-row-Ada Chen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["friend-row-Sam Okafor"].exists)
        XCTAssertTrue(app.buttons["friend-row-Dana Lee"].exists)
        XCTAssertTrue(app.buttons["friend-row-Ada Chen"].label.contains("Fresh location"))
        XCTAssertTrue(app.buttons["friend-row-Sam Okafor"].label.contains("Stale location"))
    }

    func testEmptyFriendDataShowsStatusInMapAndList() {
        app.launchArguments.append("--ui-testing-empty-friends")
        app.launch()

        let mapStatus = app.descendants(matching: .any)["friend-feed-status-banner"]
        XCTAssertTrue(mapStatus.waitForExistence(timeout: 5))
        XCTAssertEqual(mapStatus.label, "No friends to show")

        openFriendStatus()
        let listStatus = app.descendants(matching: .any)["friends-list-status"].firstMatch
        XCTAssertTrue(listStatus.exists)
        XCTAssertEqual(listStatus.value as? String, "No recent friend location data is available right now.")
    }

    func testFriendDataErrorShowsStatusInMapAndList() {
        app.launchArguments.append("--ui-testing-friend-error")
        app.launch()

        let mapStatus = app.descendants(matching: .any)["friend-feed-status-banner"]
        XCTAssertTrue(mapStatus.waitForExistence(timeout: 5))
        XCTAssertEqual(mapStatus.label, "Unable to load friends")

        openFriendStatus()
        let listStatus = app.descendants(matching: .any)["friends-list-status"].firstMatch
        XCTAssertTrue(listStatus.exists)
        XCTAssertEqual(listStatus.value as? String, "Friend location data is unavailable.")
    }

    func testSelectingFriendFromListMarksThemAsFollowed() {
        app.launch()
        openFriendList()

        app.buttons["friend-row-Ada Chen"].tap()
        openFriendList()

        XCTAssertEqual(app.buttons["friend-row-Ada Chen"].value as? String, "Following")
    }

    func testManualMapPanStopsFollowingSelectedFriend() {
        app.launch()
        openFriendList()

        app.buttons["friend-row-Ada Chen"].tap()
        let map = app.descendants(matching: .any)["friends-map"]
        XCTAssertTrue(map.waitForExistence(timeout: 5))
        map.swipeLeft()
        openFriendList()

        XCTAssertNotEqual(app.buttons["friend-row-Ada Chen"].value as? String, "Following")
    }

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let measuredApp = XCUIApplication()
            measuredApp.launchArguments = ["--ui-testing"]
            measuredApp.launch()
        }
    }

    private func openFriendList() {
        app.activate()
        XCTAssertTrue(app.buttons["friends-list-button"].waitForExistence(timeout: 5))
        app.buttons["friends-list-button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["friends-list"].waitForExistence(timeout: 5))
    }

    private func openFriendStatus() {
        app.activate()
        XCTAssertTrue(app.buttons["friends-list-button"].waitForExistence(timeout: 5))
        app.buttons["friends-list-button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["friends-list-status"].waitForExistence(timeout: 5))
    }
}
