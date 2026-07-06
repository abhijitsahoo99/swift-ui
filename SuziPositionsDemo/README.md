# SuziPositionsDemo

A **self-contained SwiftUI reproduction** of Suzi's Positions / Orders sheet,
built for testing animations in isolation. No networking, no view models, no
backend — pure static fixtures.

## What's inside

| File | Contents |
|------|----------|
| `SuziPositionsDemoApp.swift` | `@main` app entry (dark mode). |
| `PositionsScreen.swift` | The screen: header, rolling title, Live/Closed pill, scroll content, bottom dock. |
| `LensTabSwitcher.swift` | Floating glass pill tab bar (Positions/Orders) with drag-to-scrub + liquid-lens. |
| `RollingText.swift` | Per-letter 3D "rolling" word swap (title + Live/Closed pill). |
| `SectionCard.swift` | Protocol cards, tap-collapse (content-height animation), row layouts, tab-switch line-stack entrance, sticky wiring. |
| `StickySection.swift` | Apple-Weather-style sticky-section scroll: pin header, slide rows under it, collapse to header, fade up on exit (ported from `WSSection`). |
| `GlassSurface.swift` | Capsule / circle glass backgrounds (native `glassEffect` on iOS 26+). |
| `LiquidLens.swift` | SwiftUI bridge to the Metal lens shader + metric constants. |
| `LiquidLens.metal` | `suziLiquidLens` refraction shader (drives the tab indicator on drag). |
| `Theme.swift` | Colors / Typography / Spacing / Haptics tokens. |
| `Models.swift` | Mock models + sample data matching the screenshot. |

## The animations to play with

1. **Rolling title** — tap/scrub the tab bar: "Positions" ⟷ "Orders" tumbles letter-by-letter with a staggered 3D roll + motion blur.
2. **Rolling status** — tap the "Live" pill: "Live" ⟷ "Closed" rolls the same way.
3. **Liquid-glass tab switcher** — drag across the pill; the `suziLiquidLens` Metal shader bends the tab content under the indicator only while dragging. The pink indicator uses a snappy spring.
4. **Collapsible cards** — tap a protocol header (Hyperliquid / Polymarket); the card animates its content height to zero via an `Animatable` modifier (buttery, no snap), and the sections below slide up.
5. **Line-stack entrance** — sections fade + rise in with a per-section stagger on load and on tab switch.
6. **Sticky protocol sections** — scroll the list (there's deliberately a lot of mock data): each protocol header pins to the top while its rows slide up underneath it, the card collapses to just the header band (its value badge fading out to stay slim), then scales + fades up as the next protocol takes over — the Apple-Weather section effect. Lives in `StickySection.swift`; coexists with tap-collapse. Tunables (fade distance/scale, badge-fade distance) are in `StickyConfig`.

## Setup (fresh Xcode project)

1. Xcode → **New → Project → iOS → App** (SwiftUI, Swift). Delete the generated
   `ContentView.swift` and the generated `App.swift`.
2. Drag **all** files in this folder into the project (check "Copy items if
   needed" and add to the app target). The `.metal` file must be a member of the
   app target — Xcode compiles it into the default `metallib` automatically, so
   `ShaderLibrary.suziLiquidLens` resolves at runtime.
3. **Deployment target: iOS 17.0+** (needed for `layerEffect` + the two-param
   `onChange`). The native `glassEffect` paths light up on iOS 26; everything
   falls back gracefully below that.
4. Build & run. `PositionsScreen()` is the root view.

Verified: `swiftc -typecheck` passes in both Swift 5 and Swift 6 language modes;
`metal -c` compiles the shader clean.

## Notes / simplifications vs. production

- Token/protocol logos and market avatars are rendered as colored circles with
  initials or SF Symbols (`Glyph` in `Models.swift`) instead of remote images —
  swap in `AsyncImage` via the `.remote(URL, fallback:)` case if you want real art.
- Custom app icons (`PositionIcon`, `OrdersIcon`, `DownIcon`, `BrowserIcon`) are
  substituted with SF Symbols.
- Dropped (backend-coupled, not needed to test motion): drag-to-dismiss sheet,
  in-app protocol browser + split-open transition, position-detail sheet,
  share-PnL reveal, filters sheet, WebSocket/live data.
