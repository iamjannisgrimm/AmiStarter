import SwiftUI

struct FriendsListView: View {
    let viewModel: NearbyFriendsViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

                        Text(annotation.isStale ? "Stale location" : "Fresh location")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.followedFriendID == annotation.id {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Friends")
    }
}

#Preview {
    FriendsListView(viewModel: NearbyFriendsViewModel())
}
