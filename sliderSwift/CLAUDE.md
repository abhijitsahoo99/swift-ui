# sliderSwift — buy → confirmation flow

A SwiftUI prototype of a token-purchase flow, built to the Figma file
`mobile-ios · UUIJ7JRhScxoWJp7pbCf0N`. **Everything on screen is real UI; nothing
behind it is real.** There is no network, no wallet, no chain. This document is
the handover brief: what is here, where the seams are, and what to be careful of.

## Build

- Xcode 26.6+, iOS 26.0 deployment target. The screens use iOS 26 APIs
  (`.buttonStyle(.glass)`, `.glassEffect`, `keyframeAnimator(trigger:)`).
- **The Metal toolchain is a separate download** and Xcode does not ship with it.
  Until it is installed, `WallpaperGradient.metal` fails to compile and the whole
  target fails with it:
  ```
  xcodebuild -downloadComponent MetalToolchain
  ```
- Simulator run:
  ```
  xcodebuild -project sliderSwift.xcodeproj -scheme sliderSwift \
    -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath build build
  ```
- `project.pbxproj` uses `objectVersion = 77` and file-system-synchronized
  groups: **files added to `sliderSwift/` or `sliderSwiftTests/` on disk are
  picked up automatically**, no project edit needed.
- Tests: `Cmd+U`, or
  ```
  xcodebuild test -project sliderSwift.xcodeproj -scheme sliderSwift \
    -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath build
  ```

## Map

```
sliderSwiftApp.swift        @main → BuyScreen
BuyScreen.swift             keypad half; owns all the fake data and the stubs
BoughtScreen.swift          confirmation; processing → success | failure
AmountEntry.swift           what the keypad edits + the rules for buying it
Theme.swift                 design tokens (colour + type ramp) lifted from Figma
Components/
  AmountHeader              the 64pt amount + conversion row
  Numpad                    keypad
  DepositMeter              the pink capacity meter
  PayWithPill               funding-token selector
  FeeDetailsTab             fee row above the slider
  SlideToBuyBar             thin wrapper configuring LiquidGlassSlider
  GlassPillButton           Close / Buy Again
  ShimmerLabel              "Buying PUDGY" with the swept highlight
  OutcomeSweep              the black → green flush (two layers, see below)
  WallpaperGradient         SwiftUI host for the Metal shader
Helpers/
  LiquidGlassSlider         the slide-to-confirm gesture control
  WallpaperGradient.metal   the drifting green field

sliderSwiftTests/
  AmountEntryTests          16 checks over the typing and validation rules
```

**Start at `AmountEntry.swift`.** It holds the amount, the keypad's editing
rules, and the reasons a buy can be refused, with no SwiftUI in sight — which is
why it is the one part with tests. If you change what counts as a valid amount,
change it there and the keypad, the meter, the slide bar and the "Max" button
all follow.

## What to wire up

Every stub is marked in-source with a comment saying it is not wired. In order of
importance:

### 1. The outcome is decided before the screen opens — and a real buy is not

`BuyScreen` alternates success/failure off a counter (`buyCount`) and hands the
decided result to `BoughtScreen` as a value. `BoughtScreen` then *simulates* the
wait with `try? await Task.sleep(for: processingDuration)` — a flat 2 seconds.

A real chain buy is pending for an unknown time, so this is the one structural
change the integration needs:

```swift
// BoughtScreen
var resolve: () async -> Outcome

.task {
    async let result = resolve()
    try? await Task.sleep(for: Self.processingDuration)   // keeps the 2s floor
    let outcome = await result
    ...
}
```

**Watch the layout when you do.** `blockHeight` is 377 on success and 248 on
failure, and it is applied from the *first* frame so the token's resting place is
fixed before the result is known. With the outcome no longer known up front, that
switch has to move: either hold 377 for both (the failure frame then has empty
space below its status line) or animate the height at settle and accept the token
drifting ~64pt. Do not simply make `blockHeight` reactive — the whole point of
reserving it is that the token does not move.

Also decide what happens on a timeout: there is currently no third state.

### 2. Stubs

| Where | What |
|---|---|
| `BuyScreen.onViewTransaction` | open the tx in an explorer — needs a hash |
| `AmountHeader`'s swap button | flip the input currency |
| `PayWithPill` action | open the funding-token picker |
| `FeeDetailsTab` action | expand the fee breakdown |
| `DepositMeter`'s "Max" | fills `spendable` — wire that to the real figure |

### 3. Hardcoded data, all in `BuyScreen`

`amount` (seeded `"126.89"`), `balance`, `spendable`, `pudgyPerDollar` (a
constant chosen so the design's numbers come out — a real integration quotes a
price, and should re-quote while the sheet is open), and the `fundingSymbol` /
`tokenSymbol` strings. The token image is a **baked asset** (`pudgy.imageset`),
used by both `BoughtScreen` and `AmountHeader` — a real app wants a remote image
with a placeholder.

## Things that will bite you

- **`Timer.publish` stored on a `View` never fires.** A `let` publisher is rebuilt
  on every `body` pass, so `.onReceive` re-subscribes to a fresh one and the
  interval never elapses. Use `TimelineView(.animation(paused:))`.
- **`keyframeAnimator(repeating: false)` does not play if the view is mounted
  inside an animated transaction.** It sits at its initial value. Use the
  `trigger:` form and `MoveKeyframe` to the opening value — that is why
  `pulseRelease` is always mounted and fired by `releaseTrigger`.
- **Decorative layers belong in `.background`, not as `ZStack` siblings.** The
  ripple as a sibling sized the whole block and pushed the copy 91pt down the
  screen.
- **`scaleEffect` scales strokes.** The ripple rings animate their *diameter* via
  `.frame` for exactly this reason.
- **Gradient stop locations must stay in `0...1` and non-decreasing.** A negative
  location silently scrambles the whole gradient — hence `clamp` in
  `OutcomeSweep`.
- **Ramp to `colour.opacity(0)`, never to `Color.clear`.** `.clear` is transparent
  *black*, so fading to it drags midtones down and leaves a dim smear.
- **SourceKit reports false cross-file errors in this project** ("Cannot find
  'Theme' in scope", "No such module 'UIKit'"). `xcodebuild` is the only signal
  that counts.

## The confirmation animation

Timings are all `private static let` constants at the top of `BoughtScreen`, named
and commented. The sequence:

```
0.00  token rises out of centre screen, one turn about Y   (riseDuration 0.38)
0.38  "Buying PUDGY" shimmers in; ripple rings start looping
2.38  haptic; tick or cross lands; headline + buttons rise  (settle, 0.6s)
2.78  ripple releases (fades where it stands, 0.45s)        (settleBeforeSweep)
2.78  success only: black → green flush                     (sweepDuration 1.6)
```

`OutcomeSweep` draws in **two layers on opposite sides of the content**: `.field`
(the Metal green) goes behind so copy stays readable, `.band` (the bright edge)
goes in front so it washes over the text as it passes. One layer cannot do both.

The failure path has no flush — the screen stays on `Theme.background`, and the
cross plus "Transaction Failed" carry the result.

`WallpaperGradient.metal` keeps drifting for as long as the screen is up. If
battery matters, pause it once the flush has settled.

## Two numbers, and what each one means

`BuyScreen` holds both on purpose:

- **`balance`** (325.65) is the wallet total. It is shown in the pay-with pill
  and used for nothing else.
- **`spendable`** (288.39) is what may actually be committed, the rest being held
  back for fees. **One number used three ways**, so they can never disagree: the
  deposit meter measures against it, "Max" fills it, and a buy above it is
  refused. The design's meter reads 44% at $126.89, which is what fixes it here.

Whatever the backend calls these, keep the shape: the number you validate against
must be the number "Max" fills, or "Max then slide" gets rejected.

## Money is `Decimal`, and never a float literal

Amounts are `Decimal` throughout — see the header of `AmountEntry.swift` for why.
The trap that survives the type change:

```swift
let spendable: Decimal = 288.39      // ← 288.38999999999998635…
let spendable: Decimal = .money("288.39")   // ← 288.39
```

Swift routes float literals through `Double` before they reach `Decimal`, so the
first line does not hold the number you wrote, and comparing it against the same
figure typed on the keypad (parsed from a string, and exact) fails. `.money(_:)`
is in `AmountEntry.swift`; use it for every money constant. There is a test
pinning this, because it is invisible until a boundary case hits it.

## Not done

- **No Dynamic Type.** Every size in `Theme` is a fixed point value, and several
  widths (354, 297, 103) are hardcoded to the design's 402pt frame. Supporting it
  means giving up the pixel match with Figma, so it is a product decision rather
  than an oversight — but it is the largest accessibility gap left.
- **No localization.** All copy is inline English literals. The *numbers* are
  already locale-correct: the keypad's separator key follows the device and
  `AmountEntry` stores a canonical form regardless.
- **No timeout on the confirmation screen.** Once the 2s sleep becomes a real
  call, a hung request leaves the user watching the token with no way out. Pair
  this with item 1 above.
- **The buy sheet has a grabber but is not a sheet.** `BuyScreen.grabber` is the
  drag handle from the Figma frame, which was drawn as a bottom sheet. As the
  root view it is decoration. Keep it if you present this modally; drop it if you
  push it as a full screen.
- **Success/failure copy differs from Figma on purpose.** The frames set both
  lower-case and the success frame misspells "succesfully"; `statusLine` uses
  title case and the correct spelling.
- **Portrait only, iPhone only.** Nothing is laid out for iPad or landscape, and
  several widths (354, 297) are hardcoded to the design's 402pt frame.

## Provenance

`Helpers/LiquidGlassSlider.swift` is adapted from a third-party slide-to-confirm
control — the drag/spring core is that original's; the glass dressing it shipped
with was dropped and the visuals rebuilt to the Figma spec. **Check its licence
before shipping.** Everything else in the project is original.
