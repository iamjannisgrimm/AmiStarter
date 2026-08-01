//
//  ContentView.swift
//  AmiStarter
//
//  Created by Jannis on 7/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: NearbyFriendsViewModel
    @State private var isShowingFriendsList = false

    @MainActor
    init() {
        self.init(viewModel: NearbyFriendsViewModel())
    }

    init(viewModel: NearbyFriendsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            NearbyFriendsMapView(viewModel: viewModel)
                .navigationTitle("AmiStarter")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isShowingFriendsList = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                        .accessibilityLabel("Friends")
                        .accessibilityIdentifier("friends-list-button")
                    }
                }
                .sheet(isPresented: $isShowingFriendsList) {
                    NavigationStack {
                        FriendsListView(viewModel: viewModel)
                    }
                    .frame(
                        minWidth: 360,
                        idealWidth: 420,
                        maxWidth: 560,
                        minHeight: 520,
                        idealHeight: 640
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
        }
        .task {
            await viewModel.loadFriends()
        }
    }
}

#Preview {
    ContentView()
}
