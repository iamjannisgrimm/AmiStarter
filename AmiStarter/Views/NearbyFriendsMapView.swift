import MapKit
import SwiftUI

struct NearbyFriendsMapView: View {
    let viewModel: NearbyFriendsViewModel

    @State private var mapPosition: MapCameraPosition
    @State private var displayedAnnotations: [FriendMapAnnotation]
    @State private var movingFriendIDs = Set<Friend.ID>()
    @State private var isUpdatingMapForFollow = false
    @State private var annotationAnimationTask: Task<Void, Never>?

    init(viewModel: NearbyFriendsViewModel) {
        self.viewModel = viewModel
        _mapPosition = State(wrappedValue: .region(viewModel.initialRegion))
        _displayedAnnotations = State(wrappedValue: viewModel.friendAnnotations)
    }

    var body: some View {
        Map(position: $mapPosition) {
            Marker("You", systemImage: "location.fill", coordinate: viewModel.userLocation)
                .tint(.blue)

            ForEach(displayedAnnotations) { annotation in
                Annotation(annotation.displayName, coordinate: annotation.coordinate) {
                    Button {
                        follow(annotation)
                    } label: {
                        FriendMapMarker(
                            annotation: annotation,
                            isFollowed: viewModel.followedFriendID == annotation.id,
                            isMoving: movingFriendIDs.contains(annotation.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(annotation.displayName)
                    .accessibilityIdentifier("friend-map-marker-\(annotation.friend.displayName)")
                }
            }
        }
        .accessibilityIdentifier("friends-map")
        .mapControls {
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .overlay(alignment: .top) {
            if let statusMessage = viewModel.statusMessage {
                FriendFeedStatusBanner(statusMessage: statusMessage)
                    .padding()
            }
        }
        .onChange(of: viewModel.friendAnnotations, initial: true) { oldAnnotations, newAnnotations in
            animateAnnotations(from: oldAnnotations, to: newAnnotations)
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
        .onDisappear {
            annotationAnimationTask?.cancel()
            annotationAnimationTask = nil
            movingFriendIDs.removeAll()
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

    private func animateAnnotations(
        from oldAnnotations: [FriendMapAnnotation],
        to newAnnotations: [FriendMapAnnotation]
    ) {
        annotationAnimationTask?.cancel()
        movingFriendIDs.removeAll()

        let movedIDs = movedFriendIDs(from: oldAnnotations, to: newAnnotations)

        movingFriendIDs.formUnion(movedIDs)

        guard !movedIDs.isEmpty else {
            displayedAnnotations = newAnnotations
            return
        }

        annotationAnimationTask = Task { @MainActor in
            let animationDuration: TimeInterval = 0.85
            let frameCount = 30
            let frameDelay = Int((animationDuration / Double(frameCount)) * 1_000)

            for frame in 1...frameCount {
                if Task.isCancelled { return }

                let progress = Double(frame) / Double(frameCount)
                displayedAnnotations = interpolatedAnnotations(
                    from: oldAnnotations,
                    to: newAnnotations,
                    progress: easedAnimationProgress(progress)
                )

                try? await Task.sleep(for: .milliseconds(frameDelay))
            }

            if Task.isCancelled { return }

            displayedAnnotations = newAnnotations
            movingFriendIDs.subtract(movedIDs)
        }
    }

    private func movedFriendIDs(
        from oldAnnotations: [FriendMapAnnotation],
        to newAnnotations: [FriendMapAnnotation]
    ) -> Set<Friend.ID> {
        let oldCoordinatesByID = Dictionary(uniqueKeysWithValues: oldAnnotations.map { annotation in
            (annotation.id, annotation.coordinate)
        })

        return Set(newAnnotations.compactMap { annotation in
            guard let oldCoordinate = oldCoordinatesByID[annotation.id],
                  oldCoordinate.latitude != annotation.coordinate.latitude
                    || oldCoordinate.longitude != annotation.coordinate.longitude
            else {
                return nil
            }

            return annotation.id
        })
    }

    private func interpolatedAnnotations(
        from oldAnnotations: [FriendMapAnnotation],
        to newAnnotations: [FriendMapAnnotation],
        progress: Double
    ) -> [FriendMapAnnotation] {
        let oldAnnotationsByID = Dictionary(uniqueKeysWithValues: oldAnnotations.map { annotation in
            (annotation.id, annotation)
        })

        return newAnnotations.map { annotation in
            guard let oldAnnotation = oldAnnotationsByID[annotation.id] else {
                return annotation
            }

            var friend = annotation.friend
            friend.coordinate = CLLocationCoordinate2D(
                latitude: interpolatedValue(
                    from: oldAnnotation.coordinate.latitude,
                    to: annotation.coordinate.latitude,
                    progress: progress
                ),
                longitude: interpolatedValue(
                    from: oldAnnotation.coordinate.longitude,
                    to: annotation.coordinate.longitude,
                    progress: progress
                )
            )

            return FriendMapAnnotation(friend: friend, isStale: annotation.isStale)
        }
    }

    private func interpolatedValue(
        from start: CLLocationDegrees,
        to end: CLLocationDegrees,
        progress: Double
    ) -> CLLocationDegrees {
        start + (end - start) * progress
    }

    private func easedAnimationProgress(_ progress: Double) -> Double {
        let inverseProgress = 1 - progress

        return 1 - inverseProgress * inverseProgress * inverseProgress
    }
}

#Preview {
    NearbyFriendsMapView(viewModel: NearbyFriendsViewModel())
}

private struct FriendMapMarker: View {
    let annotation: FriendMapAnnotation
    let isFollowed: Bool
    let isMoving: Bool

    @State private var showsMovementPulse = false
    @State private var movementPulseExpanded = false

    var body: some View {
        ZStack {
            if showsMovementPulse {
                Circle()
                    .stroke(annotation.isStale ? .gray : .orange, lineWidth: 2)
                    .frame(width: 34, height: 34)
                    .scaleEffect(movementPulseExpanded ? 1.8 : 1)
                    .opacity(movementPulseExpanded ? 0 : 0.55)
            }

            Image(systemName: annotation.systemImageName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(annotation.isStale ? .gray : .orange, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                .scaleEffect(isMoving ? 1.08 : 1)
                .overlay {
                    if isFollowed {
                        Circle()
                            .stroke(.blue, lineWidth: 3)
                    }
                }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isMoving)
        .onChange(of: isMoving) { _, newValue in
            guard newValue else { return }

            playMovementPulse()
        }
    }

    private func playMovementPulse() {
        movementPulseExpanded = false
        showsMovementPulse = true

        Task { @MainActor in
            await Task.yield()

            withAnimation(.easeOut(duration: 0.85)) {
                movementPulseExpanded = true
            }

            try? await Task.sleep(for: .milliseconds(850))
            showsMovementPulse = false
            movementPulseExpanded = false
        }
    }
}

private struct FriendFeedStatusBanner: View {
    let statusMessage: FriendFeedStatusMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusMessage.systemImageName)
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusMessage.title)
                    .font(.headline)

                Text(statusMessage.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statusMessage.title)
        .accessibilityValue(statusMessage.message)
        .accessibilityIdentifier("friend-feed-status-banner")
    }
}
