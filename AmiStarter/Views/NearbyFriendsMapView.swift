import MapKit
import SwiftUI

struct NearbyFriendsMapView: View {
    @State private var viewModel = NearbyFriendsViewModel()

    var body: some View {
        Map(initialPosition: .region(viewModel.initialRegion)) {
            Marker("You", systemImage: "location.fill", coordinate: viewModel.userLocation)
                .tint(.blue)

            ForEach(viewModel.friendAnnotations) { annotation in
                Marker(
                    annotation.displayName,
                    systemImage: annotation.systemImageName,
                    coordinate: annotation.coordinate
                )
                .tint(annotation.isStale ? .gray : .orange)
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
