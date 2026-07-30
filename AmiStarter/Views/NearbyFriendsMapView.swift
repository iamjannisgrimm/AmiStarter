import MapKit
import SwiftUI

struct NearbyFriendsMapView: View {
    @State private var viewModel = NearbyFriendsViewModel()

    var body: some View {
        Map(initialPosition: .region(viewModel.initialRegion)) {
            Marker("You", systemImage: "location.fill", coordinate: viewModel.userLocation)
                .tint(.blue)

            ForEach(viewModel.friends) { friend in
                Marker(friend.displayName, systemImage: "person.fill", coordinate: friend.coordinate)
                    .tint(.orange)
            }
        }
        .mapControls {
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .task {
            await viewModel.loadFriends()
        }
    }
}

#Preview {
    NearbyFriendsMapView()
}
