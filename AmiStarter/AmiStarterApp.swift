//
//  AmiStarterApp.swift
//  AmiStarter
//
//  Created by Jannis on 7/28/26.
//

import SwiftUI

@main
struct AmiStarterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: makeViewModel())
        }
    }

    @MainActor
    private func makeViewModel() -> NearbyFriendsViewModel {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--ui-testing") {
            return NearbyFriendsViewModel(
                friendService: UITestFriendService(scenario: uiTestScenario(from: arguments)),
                notificationService: AuthorizedNoopNearbyFriendNotificationService(),
                now: { Date(timeIntervalSince1970: 1_800) }
            )
        }

        return NearbyFriendsViewModel()
    }

    private func uiTestScenario(from arguments: [String]) -> UITestFriendService.Scenario {
        if arguments.contains("--ui-testing-empty-friends") {
            return .empty
        }

        if arguments.contains("--ui-testing-friend-error") {
            return .failure
        }

        return .populated
    }
}
