# MenuFolder

A dead-simple, open-source macOS menu bar organizer.

MenuFolder is one feature: a folder icon in your macOS menu bar for hiding menu bar icons until you need them. It is free forever, intentionally minimal, and built in the open.

## Screenshot

Screenshot coming soon.

## Status

MenuFolder is currently in an early v0.1 build. The app shell, menu bar icon, permissions screen, management window, live menu bar item detection, persisted hidden selections, and first hide/expand/restore path are in place.

Some Apple-controlled menu extras may refuse movement. MenuFolder fails quietly for those items rather than forcing unsafe behavior.

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

MenuFolder needs Accessibility permission to detect and move the menu bar icons you choose.

MenuFolder may ask for Screen Recording permission to read screen metadata on macOS versions or configurations that require it. The current v0.1 movement path is Accessibility-based.

The app opens the matching System Settings panes from the first-run permissions screen. MenuFolder does not include analytics, telemetry, accounts, or network calls.

## How It Works

MenuFolder is a menu-bar-only AppKit agent with a native `NSStatusItem` and small SwiftUI windows for permissions and item management.

macOS does not let one app literally own another app's `NSStatusItem`. MenuFolder works the way menu bar organizers usually do: it keeps its own folder icon visible, detects other menu bar extras, then moves selected extras.

It detects menu bar extras through each running app's Accessibility `AXExtrasMenuBar`, stores the user's hidden item IDs and restore positions in `UserDefaults`, and attempts to move selected items off-screen while collapsed. Clicking the folder icon lays the hidden items out inline to the left of the folder icon; clicking again collapses them. When the app quits, it restores hidden items to their saved original positions.

## Contributing

Keep MenuFolder small. The project does not accept presets, profiles, automation rules, themes, paid-tier scaffolding, analytics, or drag-and-drop for v1.

See `CONTRIBUTING.md` for details.

## License

MIT
