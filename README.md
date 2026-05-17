# MenuFolder

A dead-simple, open-source macOS menu bar organizer.

MenuFolder is one feature: a folder icon in your macOS menu bar for hiding menu bar icons until you need them. It is free forever, intentionally minimal, and built in the open.

## Screenshot

Screenshot coming soon.

## Status

MenuFolder is currently in v0.1 Phase 1. The app shell, menu bar icon, permissions screen, management window wiring, documentation, and CI are in place. The real hide/show mechanism is stubbed for Phase 2.

## Install

There is no packaged release yet. For now, build from source with Xcode.

## Build From Source

1. Install Xcode 26 or newer.
2. Clone this repository.
3. Open `MenuFolder.xcodeproj`.
4. Select the `MenuFolder` scheme.
5. Build and run.

From the command line:

```sh
xcodebuild -project MenuFolder.xcodeproj -scheme MenuFolder -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## Permissions

MenuFolder needs Accessibility permission to move menu bar icons you choose.

MenuFolder needs Screen Recording permission to detect menu bar icons and their positions.

The app opens the matching System Settings panes from the first-run permissions screen. MenuFolder does not include analytics, telemetry, accounts, or network calls.

## How It Works

Phase 1 creates the menu-bar-only app foundation with a native `NSStatusItem`, SwiftUI windows for permissions and management, and persistent placeholder hidden item selections.

Phase 2 will add live menu bar item detection and the actual hide/show implementation. The movement strategy is intentionally not locked in yet.

## Contributing

Keep MenuFolder small. The project does not accept presets, profiles, automation rules, themes, paid-tier scaffolding, analytics, or drag-and-drop for v1.

See `CONTRIBUTING.md` for details.

## License

MIT
