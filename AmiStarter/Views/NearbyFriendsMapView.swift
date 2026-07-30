import MapKit
import SwiftUI

struct NearbyFriendsMapView: View {
    let viewModel: NearbyFriendsViewModel

    @State private var mapPosition: MapCameraPosition
    @State private var isUpdatingMapForFollow = false

    init(viewModel: NearbyFriendsViewModel) {
        self.viewModel = viewModel
        _mapPosition = State(wrappedValue: .region(viewModel.initialRegion))
    }

    var body: some View {
        Map(position: $mapPosition) {
            Marker("You", systemImage: "location.fill", coordinate: viewModel.userLocation)
                .tint(.blue)

            ForEach(viewModel.friendAnnotations) { annotation in
                Annotation(annotation.displayName, coordinate: annotation.coordinate) {
                    Button {
                        follow(annotation)
                    } label: {
                        Image(systemName: annotation.systemImageName)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(annotation.isStale ? .gray : .orange, in: Circle())
                            .overlay {
                                if viewModel.followedFriendID == annotation.id {
                                    Circle()
                                        .stroke(.blue, lineWidth: 3)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(annotation.displayName)
                }
            }
        }
        .mapControls {
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .onChange(of: viewModel.followedFriendMapFocus) { _, focus in
            guard focus != nil, let region = viewModel.followedFriendRegion else { return }

            centerMap(on: region)
        }
        .onChange(of: mapPosition.positionedByUser) { _, positionedByUser in
            if positionedByUser, !isUpdatingMapForFollow {
                viewModel.stopFollowing()
            }
        }
    }

    private func follow(_ annotation: FriendMapAnnotation) {
        viewModel.followFriend(id: annotation.id)

        if let region = viewModel.followedFriendRegion {
            centerMap(on: region)
        }
    }

    private func centerMap(on region: MKCoordinateRegion) {
        isUpdatingMapForFollow = true

        withAnimation(.easeInOut) {
            mapPosition = .region(region)
        }

        Task { @MainActor in
            await Task.yield()
            isUpdatingMapForFollow = false
        }
    }
}

#Preview {
    NearbyFriendsMapView(viewModel: NearbyFriendsViewModel())
}
