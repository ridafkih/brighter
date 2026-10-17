# Brighter

macOS menu-bar app that unlocks the extra brightness of XDR/EDR displays for bright environments. SwiftUI `MenuBarExtra` (`.window` style), `LSUIElement`, sandboxed. macOS 15+, Swift 6 language mode, Xcode 27.

## Layout
- `project.yml`: XcodeGen manifest. Edit it, never the generated `Brighter.xcodeproj` (gitignored, as are the generated `App/Info.plist` and `App/Brighter.entitlements`; change those through `project.yml`).
- `App/`: thin app target. `BoostController` (state machine + system events), `EDRTriggerWindow` (1px Metal EDR window), `GammaController` (per-display transfer table), `MenuView`, `LoginItem`.
- `Packages/BrighterCore`: pure, testable logic (`BoostMath`, `GammaTable`). Anything that can be tested without AppKit goes here.

## Commands
- `make test`: `swift test` on BrighterCore (fast inner loop).
- `make build`: regenerate project + `xcodebuild` Debug into `build/`.
- `make run`: build, kill any running copy, launch.
- Settings live in the sandbox container: `~/Library/Containers/com.ridafkih.Brighter/Data/Library/Preferences/com.ridafkih.Brighter.plist` (`enabled`, `strength`). Toggling `enabled` there + relaunch drives the app without clicking the menu bar.

## Definition of done
- `make test` and `make build` pass with zero warnings.
- Boost changes are verified on the real XDR panel: read the transfer table and `maximumExtendedDynamicRangeColorComponentValue` from a separate probe process before/while/after. Screenshots do not show the boost (gamma is applied after capture).
- Readback of the transfer table is clamped to 1.0 on this hardware; compare clamped tables.

## Swift rules
- Default actor isolation is `MainActor` (`SWIFT_DEFAULT_ACTOR_ISOLATION`); don't sprinkle `@MainActor`. Use `@concurrent`/`nonisolated` only for real background work.
- No `@unchecked Sendable`, `nonisolated(unsafe)`, `DispatchQueue`, `Task.detached` without a stated reason. Prefer `Task.sleep(for:)` loops over timers.
- `@Observable` + `@State`/`@Bindable`/`@Environment`; never `ObservableObject`/`@Published`.
- Modern APIs only: `foregroundStyle`, `onChange(of:) { old, new in }`, `NavigationStack`. If unsure an API exists, look it up in Apple docs (sosumi.ai or Xcode MCP) instead of guessing.
- Swift Testing (`@Test`, `#expect`) for unit tests; XCTest only for UI tests.
- No code comments. No new dependencies without asking.

## Technique guardrails
- BrightIntosh is GPL-3.0: use the idea, never its code.
- Always restore the original transfer table on disengage, sleep, display reconfiguration and terminate. macOS also resets it when the process exits.
- Public APIs only (keeps App Store/sandbox viable).
