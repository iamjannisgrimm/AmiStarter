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
- `AmiStarter/Services/MockFriendService.swift`
- `AmiStarter/Views/ContentView.swift`

## Implementation Preferences

- Prefer MVVM-style organization like `PilotApp`: views stay focused on rendering and interaction, while state transformations and business rules live in view models or services.
- Introduce protocols around services or persistence when it makes testing or swapping mock/real implementations cleaner, following the `PilotApp/Persistence` pattern.
- Keep feature logic testable. Add focused tests in `AmiStarterTests` for view models, services, and data rules as they become meaningful.
- Use SwiftUI idioms and keep files small, purposeful, and named after the type they contain.
- Avoid dumping new code at the app root unless it is truly app-wide entry-point code such as `AmiStarterApp.swift`.
- Prefer local patterns already present in `PilotApp` over inventing a different architecture.

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
