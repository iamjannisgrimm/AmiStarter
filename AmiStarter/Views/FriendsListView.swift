import SwiftUI

struct FriendsListView: View {
    let viewModel: NearbyFriendsViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.friendAnnotations.isEmpty, let statusMessage = viewModel.statusMessage {
                ContentUnavailableView(
                    statusMessage.title,
                    systemImage: statusMessage.systemImageName,
                    description: Text(statusMessage.message)
                )
                .accessibilityLabel(statusMessage.title)
                .accessibilityValue(statusMessage.message)
                .accessibilityIdentifier("friends-list-status")
            } else {
                List(viewModel.friendAnnotations) { annotation in
                    Button {
                        viewModel.followFriend(id: annotation.id)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: annotation.systemImageName)
                                .foregroundStyle(annotation.isStale ? .gray : .orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(annotation.friend.displayName)
                                    .font(.headline)

                                Text(annotation.locationFreshnessLabel)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.followedFriendID == annotation.id {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(.blue)
                                    .accessibilityLabel("Following \(annotation.friend.displayName)")
                                    .accessibilityIdentifier("following-indicator-\(annotation.friend.displayName)")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(annotation.friend.displayName), \(annotation.locationFreshnessLabel)")
                    .accessibilityValue(viewModel.followedFriendID == annotation.id ? "Following" : "")
                    .accessibilityIdentifier("friend-row-\(annotation.friend.displayName)")
                }
                .accessibilityIdentifier("friends-list")
            }
        }
        .navigationTitle("Friends")
    }
}

#Preview {
    FriendsListView(viewModel: NearbyFriendsViewModel())
}
