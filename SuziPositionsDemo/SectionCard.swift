// SectionCard.swift
// Protocol-grouped section cards (Hyperliquid / Polymarket), the collapsible
// measured-height card mask, the per-row layouts, and the tab-switch
// line-stack entrance. Ported/condensed from PositionsOrdersProtocolSections,
// PositionsOrdersRowViews, and PositionsOrdersTransitions.

import SwiftUI

enum CardMetrics {
    static let headerHeight: CGFloat = 68
    static let cornerRadius: CGFloat = 28
}

// MARK: - Section height measurement

struct SectionHeightKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] { [:] }
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

extension View {
    func captureSectionHeight(_ key: String) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: SectionHeightKey.self, value: [key: geo.size.height])
            }
        )
    }
}

// MARK: - Collapsible content height (tap-collapse)
//
// Tap-collapse animates the CONTENT's height between its measured value and 0,
// so the card's layout footprint shrinks to just the header and the sections
// below slide up. The card's filled rounded background + the sticky pin/collapse
// are provided separately by `stickyCardChrome` (StickySection.swift), which
// operates on whatever the current card height is — so the two never conflict.
//
// The content is `.fixedSize`d vertically so it always reports (and is measured
// at) its natural height regardless of the collapse frame; the frame merely
// clips it. That keeps `contentHeights` correct even mid-collapse, so expanding
// animates smoothly back to the right height.

private struct CollapsibleContent: ViewModifier {
    let height: CGFloat?   // nil until measured -> render at natural height

    @ViewBuilder
    func body(content: Content) -> some View {
        if let height {
            content.modifier(AnimatableContentHeight(height: height))
        } else {
            content
        }
    }
}

private struct AnimatableContentHeight: ViewModifier, Animatable {
    var height: CGFloat
    nonisolated var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: max(height, 0), alignment: .top)
            .clipped()
    }
}

// Non-observed store of each section's live scrollView-space top (minY). Written
// every frame from a background GeometryReader; because it's a plain class (no
// @Published / @Observable) those writes never invalidate SwiftUI, so there's no
// per-frame re-render. The chevron button reads it to decide whether a section is
// currently pinned/scrolled past the top — if so, collapsing scrolls its header
// back to the top so it stays put instead of jumping away.
final class SectionMinYStore {
    var values: [String: CGFloat] = [:]
}

// MARK: - Line-stack entrance (drives opacity + offset as one animatable unit)

private struct LineStackEffect: ViewModifier, Animatable {
    var progress: CGFloat
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity(Double(progress))
            .offset(y: (1 - progress) * 16)
    }
}

private struct LineStackModifier: ViewModifier {
    let index: Int
    let sequence: Int

    @State private var progress: CGFloat = 0
    @State private var animatedSequence = -1

    private var delay: Double { index < 8 ? min(Double(index) * 0.06, 0.4) : 0 }
    private var entrance: Animation { .timingCurve(0.16, 1, 0.3, 1, duration: 0.32) }

    func body(content: Content) -> some View {
        content
            .modifier(LineStackEffect(progress: progress))
            // Staggered entrance on first mount (and on tab switch, since the
            // swapped-in sections are freshly mounted).
            .onAppear {
                animatedSequence = sequence
                progress = 0
                withAnimation(entrance.delay(delay)) { progress = 1 }
            }
            // Re-animate if the sequence bumps while the view stays mounted.
            .onChange(of: sequence) { _, newSequence in
                guard animatedSequence != newSequence else { return }
                animatedSequence = newSequence
                var t = Transaction(); t.animation = nil
                withTransaction(t) { progress = 0 }
                withAnimation(entrance.delay(delay)) { progress = 1 }
            }
    }
}

extension View {
    func positionsLineStacked(index: Int, sequence: Int) -> some View {
        modifier(LineStackModifier(index: index, sequence: sequence))
    }
}

// MARK: - Shared glyph (logo / avatar)

struct GlyphView: View {
    let glyph: Glyph

    var body: some View {
        switch glyph {
        case let .symbol(name, tint):
            Circle()
                .fill(tint.opacity(0.22))
                .overlay(
                    Image(systemName: name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(tint)
                )
        case let .initials(text, tint):
            Circle()
                .fill(tint)
                .overlay(
                    Text(text)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
        case let .remote(url, fallback):
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(fallback)
            }
        }
    }
}

// MARK: - Value badge (protocol total pill)

struct ValueBadge: View {
    let value: Double

    var body: some View {
        HStack(spacing: 6) {
            Text(Format.usd(value))
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(.textPrimary)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Colors.accentPink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.overlayFill)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color.overlayBorder, lineWidth: 1) }
    }
}

// MARK: - Protocol section card

struct ProtocolCard<Content: View>: View {
    let sectionKey: String
    let name: String
    let logo: Glyph
    let total: Double
    let showValue: Bool
    let sectionIndex: Int
    let lineSequence: Int
    // The last section in the list is special: it pins to the top but never fades
    // (nothing follows it), and collapsing it keeps it on top without scrolling.
    let isLast: Bool
    @Binding var collapsedKeys: Set<String>
    @Binding var contentHeights: [String: CGFloat]
    // Shared, non-observed store of live section positions, + a closure that
    // scrolls this section's header to the top. Both used so that collapsing a
    // pinned/scrolled section keeps it visible instead of letting it jump away.
    var minYStore: SectionMinYStore
    var scrollToTop: () -> Void
    @ViewBuilder let content: () -> Content

    private var isCollapsed: Bool { collapsedKeys.contains(sectionKey) }

    // Tap-collapse target height for the CONTENT (0 == collapsed to header only;
    // nil == not yet measured, render at natural height).
    private var collapsibleContentHeight: CGFloat? {
        if isCollapsed { return 0 }
        return contentHeights[sectionKey]
    }

    // Weather-style sticky config, keyed off the card's own metrics so the
    // pin/collapse math shrinks the card to exactly its header band.
    private var stickyConfig: StickyConfig {
        StickyConfig(cornerRadius: CardMetrics.cornerRadius,
                     headerHeight: CardMetrics.headerHeight)
    }

    var body: some View {
        // Capture only Sendable values (the projected binding + key) so the
        // @Sendable onPreferenceChange closure never captures `self` — keeps
        // it clean under Swift 6 strict concurrency.
        let heights = $contentHeights
        let key = sectionKey

        return VStack(spacing: 0) {
            header

            content()
                .frame(maxWidth: .infinity, alignment: .top)
                .allowsHitTesting(!isCollapsed)
                .captureSectionHeight(sectionKey)
                .onPreferenceChange(SectionHeightKey.self) { measured in
                    guard let h = measured[key], h > 0 else { return }
                    if heights.wrappedValue[key] != h {
                        var t = Transaction(); t.animation = nil
                        withTransaction(t) { heights.wrappedValue[key] = h }
                    }
                }
                // Tap-collapse: animate content height between measured and 0.
                .modifier(CollapsibleContent(height: collapsibleContentHeight))
                // Rows slide up under the pinned header as the section scrolls past.
                .stickyContentSlide()
        }
        // Sticky chrome: filled rounded card that pins / collapses / fades on
        // scroll — operates on whatever height the tap-collapse leaves. The last
        // section never fades (fadesOnExit: false) — it pins and stays on top.
        .stickyCardChrome(stickyConfig, fadesOnExit: !isLast)
        .positionsLineStacked(index: sectionIndex, sequence: lineSequence)
        // Track this section's live top (no re-render — writes to a plain class).
        .background {
            GeometryReader { g in
                let y = g.frame(in: .scrollView(axis: .vertical)).minY
                Color.clear.onChange(of: y, initial: true) { _, v in
                    minYStore.values[key] = v
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                Haptics.selection()
                // If we're collapsing a section that's currently pinned/scrolled
                // past the top, first bring its header back to the top so it
                // stays visible (collapses in place) instead of jumping off.
                // The LAST section is skipped: it doesn't fade, so it already
                // stays put — scrolling it would rebound and drag the previous
                // section into view from the top.
                let collapsing = !isCollapsed
                if collapsing, !isLast, (minYStore.values[sectionKey] ?? 0) < -1 {
                    scrollToTop()
                }
                withAnimation(.snappy(duration: 0.28)) {
                    if isCollapsed { collapsedKeys.remove(sectionKey) }
                    else { collapsedKeys.insert(sectionKey) }
                }
            } label: {
                HStack(spacing: 8) {
                    GlyphView(glyph: logo)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())

                    Text(name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Colors.gray)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .rotationEffect(.degrees(isCollapsed ? 180 : 0))
                        .frame(width: 16, height: 16)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            if showValue && !isCollapsed {
                ValueBadge(value: total)
                    // Fades away as the card pins, keeping the stuck header slim.
                    .stickyBadgeFade(stickyConfig)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: CardMetrics.headerHeight)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Rows

struct PerpRowView: View {
    let symbol: String
    let subtitle: String
    let leverage: String?
    let value: Double
    let pnl: Double
    let logo: Glyph

    var body: some View {
        HStack(spacing: 12) {
            GlyphView(glyph: logo)
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(symbol)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if let leverage {
                        Text(leverage)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#5D5D5D"))
                    }
                }
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#8F8F8F"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.usd(value))
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(Format.percent(pnl))
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(pnl >= 0 ? .success : .error)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
    }
}

struct PredictionRowView: View {
    let question: String
    let outcome: String
    let priceCents: Int
    let pnl: Double
    let value: Double
    let avatar: Glyph

    private var outcomeTone: Color {
        switch outcome.uppercased() {
        case "YES": return .success
        case "NO":  return .error
        default:    return .polymarketBlue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                GlyphView(glyph: avatar)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                Text(question)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                HStack(spacing: 4) {
                    Text(outcome.uppercased())
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("• \(Format.cents(priceCents))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(outcomeTone)

                Spacer()

                HStack(spacing: 8) {
                    Text(Format.percent(pnl))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(pnl >= 0 ? .success : .error)
                    Text(Format.usd(value))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct OrderRowView: View {
    let order: OrderItem

    var body: some View {
        HStack(spacing: 12) {
            GlyphView(glyph: order.logo)
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(order.symbol)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 0) {
                    Text(order.side.uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(order.side == "buy" ? .success : .error)
                    Text(" • ")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#8F8F8F"))
                    Text(order.type.capitalized)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "#8F8F8F"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.price(order.price))
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(order.amount)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#8F8F8F"))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .contentShape(Rectangle())
    }
}

// Row divider matching the sheet's inset hairline.
struct RowDivider: View {
    var body: some View {
        Divider()
            .background(Color.overlayBorder)
            .padding(.horizontal, Spacing.lg)
    }
}
