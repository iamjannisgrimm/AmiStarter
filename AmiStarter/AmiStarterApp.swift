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
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return NearbyFriendsViewModel(
                friendService: UITestFriendService(),
                notificationService: NoopNearbyFriendNotificationService(),
                now: { Date(timeIntervalSince1970: 1_800) }
            )
        }

        return NearbyFriendsViewModel()
    }
}
