# AmiStarter Decisions

## Overview

The work was deliberately divided into three phases: setup, implementation, and testing and refinement. This let the AI-assisted workflow establish clear engineering constraints before producing feature code, implement the brief incrementally, and then validate and improve the completed experience.

The result is a native SwiftUI feature built around Apple's frameworks, a small MVVM architecture, protocol-backed services, modern Swift Concurrency, and deterministic automated tests.

## Phase 1: Setup and Agent Context

The setup phase focused on giving the agent enough durable context to make consistent decisions across later sessions instead of relying only on individual prompts.

### Reference project and project guidance

`AGENTS.md` was added as the persistent implementation guide for future agents. It establishes `/Users/jannis/Documents/PilotApp` as the local reference for project organization and design patterns.

The project was organized by responsibility:

- `Models` contains domain data.
- `Views` contains SwiftUI screens and presentation logic.
- `ViewModels` owns feature state and behavior.
- `Services/Friends` contains the friend-feed abstraction and implementation.
- `Services/Notifications` contains notification protocols and implementations.
- `Services/Testing` contains deterministic app dependencies used by UI tests.
- Test targets remain separated into unit and UI tests.

This structure was chosen to remain understandable as the feature grows and to match patterns already used in the reference project.

### MVVM and dependency direction

MVVM was selected as the default architecture. Views render observable state and forward user actions. `NearbyFriendsViewModel` owns loading, staleness, proximity, notification transitions, selection, following, and error-state decisions. Models remain UI-independent, while services handle data sources and side effects.

Dependencies flow in one direction:

`Views -> ViewModels -> Models and service protocols -> service implementations`

Services are accessed through protocols and passed through constructor injection. This keeps platform side effects and the mock feed replaceable, and makes the feature logic testable without invoking real notifications or waiting for live updates.

### Native technology choices

The implementation stays close to the Apple platform and does not add third-party dependencies. The main technologies are:

- SwiftUI for application and screen UI.
- MapKit's SwiftUI `Map` APIs for the map and camera position.
- Core Location types and `CLLocation.distance(from:)` for coordinates and meter-based distance calculations.
- Swift Observation with `@Observable` for view-model state.
- UserNotifications for local notification authorization, scheduling, and foreground presentation.
- Swift Testing for unit tests.
- XCTest and XCUITest for end-to-end UI and launch tests.

Using native frameworks reduces integration overhead for a focused exercise and demonstrates current platform conventions.

### Swift Concurrency

A dedicated Swift Concurrency guide was supplied during setup and treated as an implementation constraint. The app uses `async`/`await`, `Task`, actor isolation, cancellation, and `AsyncThrowingStream`. It does not use Combine or `DispatchQueue` for application concurrency.

The view model and service protocol are main-actor isolated where they interact with app state. The original callback-based mock service is adapted to an `AsyncThrowingStream`, which represents repeated snapshots, supports termination, and gives the view model a natural error path.

## Phase 2: Feature Implementation

The brief was implemented one requirement at a time. Each addition followed the architecture established during setup and included focused tests before moving to the next requirement.

### Map rendering

Apple MapKit was selected instead of a third-party map SDK. Friends are rendered as SwiftUI map annotations at their last-known coordinates, together with a marker for the current user's reference location.

The starter's fixed San Francisco user coordinate remains the proximity reference. This keeps the exercise self-contained and avoids adding real device-location permission and lifecycle concerns that were not required by the brief.

### Stale locations

A location is stale only when it is older than 30 minutes. A location exactly 30 minutes old remains fresh. Staleness is derived in the view model using an injectable clock, which makes the boundary deterministic in tests.

Stale friends are visually distinct in both map and list presentations through gray styling, a clock warning symbol, and explicit "Stale location" text. The distinction is therefore not dependent on color alone.

### Nearby detection and notifications

Nearby means a Core Location distance less than or equal to 500 meters. The implementation uses `CLLocation.distance(from:)`, whose result is expressed in meters. A regression test places a friend 300 meters away, outside 500 feet but inside 500 meters, to make the intended unit unambiguous.

Notifications are transition-based rather than snapshot-based:

- The initial snapshot establishes the baseline and does not notify for friends who were already nearby when the app opened.
- A friend triggers an alert when moving from outside to inside the radius.
- Friends that become nearby in the same snapshot are grouped into one notification.
- A friend remaining nearby does not repeatedly trigger alerts.
- A friend can trigger again after leaving the radius and later re-entering it.
- No notification is scheduled if authorization is denied.

`NearbyFriendNotificationScheduling` separates the view model's rules from `UNUserNotificationCenter`. The concrete notification service requests permission and schedules the grouped local notification.

A `UNUserNotificationCenterDelegate` was added so banners can also be presented while the app is open. Foreground presentation requests banner, notification-list, sound, and badge behavior where supported.

### Background behavior

An already scheduled local notification may be delivered while the app is backgrounded. However, the current mock friend feed runs from the SwiftUI task while the app is active; the app does not continuously ingest new locations or calculate proximity after suspension.

True background detection would require a real background-capable data source, appropriate background modes, and a product decision around battery, privacy, and server or location update strategy. Those concerns are intentionally outside this self-contained mock-data exercise.

### Following a friend

The map is wrapped in a `NavigationStack`, with a toolbar button presenting the friend list. Selecting a friend from either the list or a map annotation stores that friend's stable identifier in the view model and moves the map camera to that person.

Following is based on identity rather than a copied coordinate. As new snapshots arrive, the selected friend is resolved from the latest data and the camera recenters on the updated coordinate. Following ends when the user explicitly stops it, manually pans the map, or the selected friend disappears from the feed.

The list is presented as a sheet. Explicit minimum and ideal dimensions prevent an undersized list on macOS and larger iPad-style presentations, while medium and large presentation detents support touch platforms.

### Location-update animation

Friend movement is animated in the view layer so the view model continues to expose the latest domain truth. Updated annotations receive a subtle pulse and scale treatment.

Because MapKit did not consistently animate a single annotation-coordinate jump on macOS, the map view interpolates displayed coordinates over approximately 0.85 seconds with an ease-out curve. The interpolation uses a cancellable Swift Concurrency task and short `Task.sleep` intervals. A newer update cancels the previous animation so stale animation work cannot overwrite current state.

## Phase 3: Testing and Refinement

The final phase expanded automated coverage across domain behavior and complete user flows, then used those results to improve resilience and cross-platform polish.

### Unit testing

Unit tests use Apple's Swift Testing framework with `@Test` and `#expect`. Dependencies are replaced with protocol-backed mocks, streams are controlled directly, and the current date and user location can be injected.

Coverage includes:

- Initial and subsequent friend snapshots.
- Fresh, stale, and exact 30-minute boundary behavior.
- Initial nearby suppression and outside-to-inside transitions.
- The 500-meter rather than 500-foot boundary.
- Grouped nearby notifications.
- No duplicate alert while a friend remains nearby.
- Re-notification after leaving and re-entering.
- Notification authorization denial and foreground presentation options.
- Following, updated follow regions, stopping follow, and disappearing friends.
- Empty snapshots and streams that finish without data.
- Service errors and user-facing error messages.
- Invalid coordinates and hidden-location warnings.
- Mock-service seed and stream behavior.

### UI and launch testing

UI tests use XCTest, `XCUIApplication`, and XCUITest accessibility queries. Stable accessibility identifiers were added for the map, toolbar action, friend rows, follow indicator, and status views.

The UI suite covers:

- App launch, map visibility, and access to the friend list.
- Fresh and stale states in the list.
- Selecting a friend and showing the followed state.
- Manual map interaction breaking follow mode.
- Empty-data and service-error states on both map and list.
- Launch performance and generated launch tests.

`UITestFriendService` provides deterministic populated, empty, and failure scenarios through launch arguments. This prevents random mock movement, notification authorization state, or platform timing from making UI tests unreliable.

System notification banners are not used as the primary automated assertion because OS-owned notification UI is timing- and permission-dependent. Instead, unit tests verify transition and grouping rules through the notification protocol, and a focused test verifies the foreground delegate's presentation options.

### Error handling and visible states

The friend stream was upgraded to `AsyncThrowingStream` so failure is part of the service contract. The view model exposes loading, ready, empty, and failed states, all of which are rendered in the UI.

Additional safeguards include:

- Invalid coordinates are filtered before creating map annotations.
- The UI explains when one or more invalid locations were hidden.
- A completed stream with no snapshot is treated as empty data.
- If notification permission is unavailable, friends remain visible and a non-blocking warning explains that alerts are off.
- If a followed friend disappears, follow mode is cleared.

These refinements were added during testing because they turn technically valid happy-path behavior into a more production-ready experience.

### Verification strategy

Swift changes were built and tested with `xcodebuild` using the available macOS destination:

```sh
xcodebuild -project /Users/jannis/Documents/AmiStarter/AmiStarter.xcodeproj \
  -scheme AmiStarter \
  -destination 'platform=macOS,name=My Mac' build

xcodebuild test \
  -project /Users/jannis/Documents/AmiStarter/AmiStarter.xcodeproj \
  -scheme AmiStarter \
  -destination 'platform=macOS,name=My Mac'
```

During the final cross-platform animation pass, two old app processes owned by `debugserver` prevented XCTest from cleaning up the first UI-test launch. The build and unit suite passed, and the later UI flows, including the friend list, continued to pass. This was treated as a local test-runner state issue rather than changing application behavior to accommodate the environment.

## Tradeoffs and Scope

- The app uses the provided mock feed and reference location rather than a backend or live device location.
- Background proximity evaluation is not claimed without a background-capable source of friend updates.
- No third-party map, reactive, dependency-injection, or testing libraries were introduced.
- The view model currently owns the complete feature because its scope remains small. It can be split into smaller domain policies if nearby, staleness, or following rules become shared across features.
- Notification rules are tested below the OS presentation layer to keep the suite deterministic.
- Animation state remains in the view because interpolated coordinates are presentation state, not domain state.

## AI-Assisted Workflow

AI was used throughout setup, implementation, testing, and refinement. Persistent project guidance and the Swift Concurrency reference constrained later implementation choices, while each brief requirement was handled as a separate increment and verified before the next one.

The submitted transcripts are divided into the same three phases:

- `Setup.txt`
- `Implementation.txt`
- `Testing.txt`

This division records both the produced code and how the project-level decisions made during setup influenced implementation and testing.
