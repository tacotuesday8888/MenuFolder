# Contributing to MenuFolder

MenuFolder is intentionally small. Contributions should preserve the core idea: one menu bar folder that hides and shows chosen menu bar icons.

## Scope

In scope:

- Reliability fixes
- Accessibility and permissions UX improvements
- Minimal management UI improvements
- Documentation and build fixes

Out of scope for v1:

- Presets, profiles, rules, or automation
- Themes or menu bar styling
- Analytics, telemetry, accounts, or network calls
- Paid-tier scaffolding
- Drag-and-drop menu bar icon management

## Development

Use Xcode 26 or newer and keep the minimum supported macOS version at macOS 14 unless the project deliberately changes that policy.

Before opening a pull request, run:

```sh
xcodebuild -project MenuFolder.xcodeproj -scheme MenuFolder -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## License

By contributing, you agree that your contribution is licensed under the MIT license.
