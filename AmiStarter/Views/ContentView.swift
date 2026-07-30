//
//  ContentView.swift
//  AmiStarter
//
//  Created by Jannis on 7/28/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = NearbyFriendsViewModel()
    @State private var isShowingFriendsList = false

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
                    }
                }
                .sheet(isPresented: $isShowingFriendsList) {
                    NavigationStack {
                        FriendsListView(viewModel: viewModel)
                    }
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
