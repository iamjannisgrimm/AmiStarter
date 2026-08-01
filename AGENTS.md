# AmiStarter Agent Notes

This project should follow the organization and design-pattern style of the reference repo at:

`/Users/jannis/Documents/PilotApp`

Use that repo as the local source of truth for how Jannis likes iOS projects structured. When in doubt, inspect `PilotApp` before adding new files or choosing a pattern.

## Project Structure

Keep `AmiStarter/AmiStarter` organized by responsibility, matching the PilotApp layout:

- `Models/`: domain/data types, value models, app-specific entities.
- `Views/`: SwiftUI screens and feature views.
- `ViewModels/`: observable view models and presentation/state logic.
- `Services/`: app services, data providers, networking or mock service abstractions.
- `Persistence/`: storage adapters, persistence protocols, real/mock persistence implementations.
- `Components/`: reusable SwiftUI components that are not full screens.
- `Preview Content/`: preview data/assets and SwiftUI preview support.
- `Assets.xcassets/`: asset catalogs only.

Current starter files are placed as:

- `AmiStarter/Models/Friend.swift`
- `AmiStarter/Services/Friends/MockFriendService.swift`
- `AmiStarter/Views/ContentView.swift`

## Implementation Preferences

- Use MVVM as the default architecture. Views render state and forward user intent; view models own screen state, validation, formatting, filtering, async orchestration, and navigation decisions; models represent domain data; services and persistence handle data access and side effects.
- Keep dependency flow one-way: `Views` depend on `ViewModels`; `ViewModels` depend on `Models`, service protocols, and persistence protocols; `Services` and `Persistence` depend on `Models`; `Models` should not depend on SwiftUI views or app infrastructure.
- Prefer constructor injection for view model dependencies. Default to protocol-backed dependencies when a service, persistence adapter, location provider, clock/date source, or mock-vs-real implementation needs to be tested or swapped.
- Introduce protocols around services or persistence when it makes testing or swapping mock/real implementations cleaner, following the `PilotApp/Persistence` pattern.
- Keep feature logic testable. Add focused tests in `AmiStarterTests` for view models, services, and data rules as they become meaningful.
- Use SwiftUI idioms and keep files small, purposeful, and named after the type they contain.
- Avoid dumping new code at the app root unless it is truly app-wide entry-point code such as `AmiStarterApp.swift`.
- Prefer local patterns already present in `PilotApp` over inventing a different architecture.

## MVVM Guidelines

- `Views`: declare layout, bind to observable state, call intent methods on view models, and contain only lightweight view-specific formatting when it is not worth extracting. Avoid business rules, data fetching, timers, location logic, persistence calls, or complex filtering directly in views.
- `ViewModels`: expose the smallest useful state surface for each screen, usually with `@Observable` or the project's existing observation style. Put loading states, empty/error states, derived display values, filtering/sorting, stale/nearby calculations, and user actions here.
- `Models`: keep domain types simple and reusable. Add computed properties only when they are truly domain concepts, not screen presentation details.
- `Services`: wrap external data sources, mock feeds, location updates, networking, or other side effects. Keep services UI-agnostic.
- `Persistence`: follow the `PilotApp` protocol/real/mock split when storing data becomes necessary.
- `Components`: extract reusable UI pieces after the shape is clear. Do not over-componentize one-off layout.
- `Preview Content`: provide sample data and preview helpers so views can be developed without live services.

## Feature Workflow

When adding a feature, prefer this order:

1. Define or update the domain model in `Models`.
2. Add a service or persistence protocol if data or side effects are involved.
3. Implement the view model in `ViewModels`, injecting dependencies.
4. Build the SwiftUI screen in `Views`, binding it to the view model.
5. Extract repeated UI into `Components` only when reuse is real.
6. Add preview data under `Preview Content`.
7. Add focused tests for the view model and service behavior.

## Testing Expectations

- View model tests should cover state transitions, derived values, sorting/filtering, stale/nearby rules, error handling, and async update behavior.
- Service tests should cover data transformation and mock feed behavior without relying on UI.
- Keep tests deterministic. Inject clocks, dates, locations, or mock services instead of depending directly on `Date()`, random values, or live platform state in testable logic.
- Do not require UI tests for every small change, but add them for critical end-to-end flows once real screens exist.

## GitHub

The AmiStarter repo is connected to:

`https://github.com/iamjannisgrimm/AmiStarter`

Push setup/structural changes after verifying the project builds.

## Verification

After structural changes or Swift code changes, verify with:

```sh
xcodebuild -project /Users/jannis/Documents/AmiStarter/AmiStarter.xcodeproj -scheme AmiStarter -destination 'platform=macOS,name=My Mac' build
```

The project may list iOS destinations as ineligible if the required iOS platform is not installed locally; use the available `My Mac` destination unless the project platform changes.
