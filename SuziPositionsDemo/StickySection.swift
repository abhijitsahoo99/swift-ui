// StickySection.swift
// Apple-Weather-style sticky-section scroll animation, ported from
// WSSection/Helpers/StickySection.swift and adapted to Suzi's fixed-height
// protocol cards. Three composable pieces layered onto an existing card:
//
//   • stickyContentSlide() — slides a card's rows UP under its pinned header.
//   • stickyCardChrome()   — pins the whole card to the top, shrinks it to the
//                            header band as its rows are consumed, then scales +
//                            fades it up on exit. Declares the SECTION space.
//   • stickyBadgeFade()    — fades the header's value badge out while pinning so
//                            the pinned header stays slim (logo + name).
//
// The crux (same trick as the reference): `.coordinateSpace(.named("SECTION"))`
// is the OUTERMOST modifier while the sticky pin `.offset` is applied just inside
// it — that ordering turns SECTION-space geometry reads into a clean
// scroll-progress signal that all three pieces share.
//
// Coexists with the tap-collapse: the card's LAYOUT height is set by
// `CollapsibleContent` (SectionCard.swift), which animates the content's height
// to 0; this chrome operates on whatever that height is. When a card is
// tap-collapsed the bottom-shrink clamps to zero, so the two never fight.
//
// The last section passes `fadesOnExit: false` — it pins but never fades, so it
// stays on top (there's no next section to replace it).

import SwiftUI

struct StickyConfig {
    /// Card corner radius — matches CardMetrics.cornerRadius.
    var cornerRadius: CGFloat = 28
    /// Collapsed height the card shrinks to — matches CardMetrics.headerHeight.
    var headerHeight: CGFloat = 68
    /// Scroll distance (pt) over which the card scales + fades out on exit.
    var fadeDistance: CGFloat = 45
    /// Max shrink at full exit (0.05 == down to 95%), anchored at the top.
    var fadeScale: CGFloat = 0.05
    /// Scroll distance (pt) over which the value badge fades as the card pins.
    var badgeFadeDistance: CGFloat = 18
}

extension View {
    /// Applied to a card's CONTENT: slides the rows up underneath the pinned
    /// header (and clips them away) as the section scrolls past the top.
    func stickyContentSlide() -> some View {
        self
            .visualEffect { content, proxy in
                let rect = proxy.frame(in: .named("SECTION"))
                let scrollMinY = proxy.frame(in: .scrollView(axis: .vertical)).minY
                let slide = max(rect.minY - scrollMinY, 0)
                return content.offset(y: -slide)
            }
            .clipped()
    }

    /// Applied to the whole card (the header + slid content stack): pins it to
    /// the top, shrinks it to the header band from the bottom as its rows are
    /// consumed, then scales + fades it up on exit. Provides the card's filled
    /// rounded background (which collapses in lock-step) and declares the SECTION
    /// coordinate space.
    ///
    /// NOTE: both the `.mask` and the `.background` read the SECTION space with
    /// the same `bottomPadding`. Keeping BOTH GeometryReaders is load-bearing —
    /// it's what makes the SECTION geometry resolve deterministically (a single
    /// reader leaves the top card's pin flickering between 0 and a phantom value).
    /// `fadesOnExit` controls the scale/opacity exit. Pass `false` for the LAST
    /// section: it still pins to the top (offset), but never scales or fades away
    /// — there's no next section to replace it, so it just stays on top.
    func stickyCardChrome(_ config: StickyConfig = .init(),
                          fill: Color = .cardFill,
                          fadesOnExit: Bool = true) -> some View {
        self
            // (C) collapse: trim the card from the bottom down to the header band.
            .mask {
                GeometryReader { proxy in
                    let bp = stickyBottomPadding(proxy, config)
                    RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
                        .padding(.bottom, bp)
                }
            }
            // Filled card background that collapses with the same bottomPadding.
            .background {
                GeometryReader { proxy in
                    let bp = stickyBottomPadding(proxy, config)
                    RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
                        .fill(fill)
                        .padding(.bottom, bp)
                }
            }
            .compositingGroup()
            // (A) pin to the top + (D) scale/fade out on exit, as one unit.
            .visualEffect { content, proxy in
                let rect = proxy.frame(in: .scrollView(axis: .vertical))
                let minY = rect.minY
                let cutoffHeight = proxy.size.height - config.headerHeight
                let distance = abs(min(cutoffHeight + minY, 0))
                // Last section: no exit fade/scale — it pins and stays on top.
                let progress = fadesOnExit ? max(min(distance / config.fadeDistance, 1), 0) : 0
                return content
                    .scaleEffect(1 - progress * config.fadeScale, anchor: .top)
                    .opacity(1 - progress)
                    .offset(y: minY < 0 ? -minY : 0)
            }
            .coordinateSpace(.named("SECTION"))
    }

    /// Applied to the header's value badge: fades it out as the card begins to
    /// pin, keeping the pinned header slim (logo + name only). Keyed on the pin
    /// signal `max(SECTION.minY - scrollView.minY, 0)` (0 at rest, growing as the
    /// card pins) — NOT the badge's raw SECTION.minY, which is already ~22 at rest
    /// because the badge sits centered in the 68pt header.
    func stickyBadgeFade(_ config: StickyConfig = .init()) -> some View {
        visualEffect { content, proxy in
            let s = proxy.frame(in: .named("SECTION")).minY
            let v = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let pin = max(s - v, 0)
            let progress = max(min(pin / config.badgeFadeDistance, 1), 0)
            return content.opacity(1 - progress)
        }
    }
}

/// Shared collapse amount for the mask + background: how far to trim the card
/// from the bottom (0 when fully expanded, up to viewHeight-headerHeight once the
/// section is fully consumed under its pinned header).
private func stickyBottomPadding(_ proxy: GeometryProxy,
                                 _ config: StickyConfig) -> CGFloat {
    let minY = proxy.frame(in: .named("SECTION")).minY
    let viewHeight = proxy.size.height
    return min(max(minY, 0), max(viewHeight - config.headerHeight, 0))
}
