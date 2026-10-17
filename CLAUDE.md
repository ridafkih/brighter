# Brighter

macOS menu-bar app that unlocks the extra brightness of XDR/EDR displays for bright environments. SwiftUI `MenuBarExtra` (`.window` style), `LSUIElement`. Not sandboxed: brightness writes through DisplayServices are silent no-ops inside the App Sandbox, so no Mac App Store. macOS 15+, Swift 6 language mode, Xcode 27.

## Layout
- `project.yml`: XcodeGen manifest. Edit it, never the generated `Brighter.xcodeproj` (gitignored, as is the generated `App/Info.plist`; change it through `project.yml`).
- `App/`: thin app target. `BoostController` (state machine + system events), `EDRTriggerWindow` (1px Metal EDR window), `GammaController` (per-display transfer table), `DisplayBrightness` (built-in display brightness), `MenuView` (panel + `LevelSlider`), `LoginItem`.
- `Packages/BrighterCore`: pure, testable logic (`BoostMath`, `GammaTable`, `SliderLevel`). Anything that can be tested without AppKit goes here.

## Commands
- `make test`: `swift test` on BrighterCore (fast inner loop).
- `make build`: regenerate project + `xcodebuild` Debug into `build/`.
- `make run`: build, kill any running copy, launch.
- Settings: `defaults read com.ridafkih.Brighter` (`enabled` only). Toggling it there + relaunch drives the app without clicking the menu bar. Run the binary with `OS_ACTIVITY_DT_MODE=1` to see the `boost` log category in the terminal.

## Definition of done
- `make test` and `make build` pass with zero warnings.
- Boost changes are verified on the real XDR panel: read the transfer table and `maximumExtendedDynamicRangeColorComponentValue` from a separate probe process before/while/after. Screenshots do not show the boost (gamma is applied after capture).
- Readback of the transfer table is clamped to 1.0 on this hardware; compare clamped tables.
- UI changes: render the panel offscreen (`NSHostingView` + `cacheDisplay`) and look at it; the terminal has no Accessibility access to click the menu bar item. The panel must never change size or move controls between states.

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
- Public APIs for the boost itself. The one private API is DisplayServices (`DisplayServicesGetBrightness`/`SetBrightness`), loaded with `dlopen` so a missing symbol degrades instead of crashing.

## Slider model
One slider. Boost off: 0–100% system brightness. Boost on: range extends to `1 + SliderLevel.boostSpan`, with a notch at 100%; past the notch is boost strength. Boost only applies at full brightness (`SliderLevel.effectiveStrength`): while past the notch, slow downward drift (auto-brightness) is pinned back to 100% every 0.5s so the boost never drops; a sharp step (`SliderLevel.isDrift` fails, e.g. a brightness key) exits the boost. Dragging below the notch also zeroes it. Turning boost on (toggle or launch) always starts at strength 0, pinned at the notch; strength is never persisted.
