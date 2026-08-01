# AmiStarter Decisions

## Overview

The project was completed in three phases: setup, implementation, and testing and refinement. This sequence allowed the AI-assisted workflow to establish engineering constraints first, apply them consistently while building the feature, and then validate and improve the result.

The final app is a native SwiftUI feature using MVVM, protocol-backed services, modern Swift Concurrency, and automated unit and UI tests.

## Phase 1: Setup

The setup phase gave the agent persistent context before implementation began.

### Project guidance and structure

`AGENTS.md` defines the project's architecture and working conventions. `/Users/jannis/Documents/PilotApp` was used as the reference for preferred iOS project organization and design patterns.

The app is organized by responsibility:

- `Models` for domain data.
- `Views` for SwiftUI presentation.
- `ViewModels` for feature state and behavior.
- `Services/Friends` for friend data.
- `Services/Notifications` for notification behavior.
- `Services/Testing` for deterministic UI-test dependencies.

This keeps files focused and provides an obvious place for future implementations.

### MVVM

MVVM was chosen to keep UI and business rules separate. Views render state and forward user actions. `NearbyFriendsViewModel` owns loading, staleness, proximity, notifications, following, and error states. Services own external data and side effects.

The dependency direction is:

`Views -> ViewModels -> Models and service protocols -> service implementations`

### Protocols and testability

Friend data and notification scheduling are defined behind protocols and injected into the view model through its initializer. This abstraction was chosen for two reasons:

- Production behavior can be replaced without changing the view model or views.
- Tests can inject controlled friend snapshots, errors, locations, authorization results, and notification recorders.

`FriendServiceProtocol` allows the app to use the live mock feed while unit tests provide exact snapshots through `AsyncThrowingStream`. `NearbyFriendNotificationScheduling` allows tests to verify notification rules without displaying real OS notifications. `UITestFriendService` supplies deterministic populated, empty, and failure data selected through launch arguments.

This protocol-backed design is what makes the feature's state transitions reliable and fast to test.

### Native frameworks

The app stays close to Apple's platform and adds no third-party dependencies:

- SwiftUI for UI and navigation.
- MapKit for the map and camera.
- Core Location for coordinates and meter-based distance calculations.
- Swift Observation with `@Observable` for view-model state.
- UserNotifications for local notifications.
- Swift Testing for unit tests.
- XCTest and XCUITest for UI, launch, and performance tests.

### Swift Concurrency

The supplied Swift Concurrency guide was treated as an implementation constraint. The app uses `async`/`await`, `Task`, main-actor isolation, cancellation, and `AsyncThrowingStream`. It does not use Combine or `DispatchQueue` for application concurrency.

The starter's callback feed is adapted into an `AsyncThrowingStream`, which naturally represents repeated snapshots, supports cancellation, and makes service failures part of the contract.

## Phase 2: Implementation

The brief was implemented one requirement at a time while following the setup decisions.

### Map and location source

MapKit's native SwiftUI `Map` API was selected instead of a third-party SDK. Friends are rendered at their last-known coordinates with the starter's fixed current-user coordinate as the proximity reference.

Using the supplied reference location keeps the feature self-contained. Live device location would introduce permissions and lifecycle behavior not required by the brief.

### Staleness

A location is stale when it is older than 30 minutes; exactly 30 minutes remains fresh. Staleness is derived in the view model with an injectable clock so the boundary can be tested deterministically.

Stale locations use gray styling, a warning icon, and an explicit label in both the map and list, so the state is not communicated by color alone.

### Nearby notifications

Nearby means a distance of 500 meters or less, calculated with `CLLocation.distance(from:)`. A regression test explicitly verifies a friend at 300 meters triggers the rule, removing any ambiguity between meters and feet.

Notifications are transition-based:

- The initial snapshot establishes a baseline and does not notify.
- A friend triggers when moving from outside to inside the radius.
- Multiple friends entering together are grouped into one notification.
- Remaining nearby does not produce repeated alerts.
- Leaving and later re-entering can trigger another alert.
- Denied authorization prevents scheduling without blocking the map.

A notification-center delegate opts into banner, list, sound, and badge presentation while the app is open.

The current mock feed is active while the app is running. An already scheduled notification can appear in the background, but new background proximity calculations would require a real background-capable data source and appropriate background modes. That is intentionally outside this exercise.

### Following

A `NavigationStack` toolbar action presents the friend list. Selecting a friend from the list or map stores the friend's identifier and centers the camera on the latest matching location.

Identity-based following means the camera continues to update as new snapshots arrive. Following ends when the user stops it, manually pans the map, or the friend disappears.

The list sheet has explicit minimum and ideal dimensions for a usable presentation on macOS and larger iPad layouts.

## Phase 3: Testing and Refinement

### Automated testing

Unit tests use Swift Testing with protocol-backed mocks and injected time, locations, streams, authorization, and notification behavior. Coverage focuses on staleness boundaries, 500-meter transitions, grouped and repeated notifications, following, empty data, service errors, invalid coordinates, and authorization denial.

UI tests use XCTest and XCUITest with stable accessibility identifiers. They cover launch, map and list presentation, fresh and stale states, following, manual-pan cancellation, empty data, service failures, and launch performance.

OS notification banners are not the primary automated assertion because system UI and permissions are timing-dependent. Notification decisions are tested through the scheduling protocol, while a focused unit test verifies foreground presentation options.

### UX refinements from testing

Testing led to several production-oriented improvements:

- Loading, empty, failure, invalid-location, and notification-disabled states are visible in the UI.
- Invalid coordinates are filtered before map rendering.
- Following clears if the selected friend disappears.
- Friend movement uses a subtle pulse and interpolated coordinate animation instead of snapping.
- Animation work is cancellable so a newer location update replaces an older animation.
- Explicit sheet sizing improves the friend list on macOS and iPad-style layouts.

Animation state remains in the view because interpolated coordinates are presentation state; the view model continues to expose the latest domain truth.

## Scope and Tradeoffs

- The provided mock feed and reference location are used instead of a backend or live device location.
- Background proximity evaluation is not claimed without a background-capable update source.
- No third-party map, reactive, dependency-injection, or testing libraries were added.
- The feature remains in one view model because its scope is small; shared rules could be extracted into domain policies if the app grows.
- Tests favor deterministic protocol-level assertions over unreliable OS-owned UI.

## AI-Assisted Process

AI was used throughout all three phases. Persistent setup guidance shaped later implementation and testing decisions, while each requirement was implemented and verified incrementally.

The accompanying transcripts follow the same division:

- `Setup.txt`
- `Implementation.txt`
- `Testing.txt`
