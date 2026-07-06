// RollingText.swift
// Per-letter "rolling" word swap — each glyph tumbles out on a 3D x-axis while
// its replacement tumbles in, with a staggered per-letter delay and motion
// blur. Used by the header title (Positions ⟷ Orders) and the Live ⟷ Closed
// status pill. Generalized from PositionsOrdersSheetView's two private copies.

import SwiftUI

// MARK: - Animatable roll modifier (offset + rotation + opacity + blur as one)

private struct RollModifier: ViewModifier, Animatable {
    typealias Data = AnimatablePair<AnimatablePair<CGFloat, Double>, AnimatablePair<Double, CGFloat>>

    var offsetY: CGFloat
    var rotation: Double
    var opacity: Double
    var blurRadius: CGFloat

    nonisolated var animatableData: Data {
        get { Data(AnimatablePair(offsetY, rotation), AnimatablePair(opacity, blurRadius)) }
        set {
            offsetY = newValue.first.first
            rotation = newValue.first.second
            opacity = newValue.second.first
            blurRadius = newValue.second.second
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .blur(radius: blurRadius)
            .offset(y: offsetY)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 1, y: 0, z: 0),
                anchor: offsetY >= 0 ? .bottom : .top,
                perspective: 0.65
            )
    }
}

private enum RollConfig {
    static let blur: CGFloat = 3.0
    static let animation = Animation.spring(response: 0.28, dampingFraction: 0.84)
    static func letterAnimation(index: Int) -> Animation { animation.delay(Double(index) * 0.024) }
}

// MARK: - Rolling word

struct RollingWord: View {
    /// Word shown when `showingB == false`.
    let wordA: String
    /// Word shown when `showingB == true`.
    let wordB: String
    let showingB: Bool

    let font: Font
    let color: Color
    let height: CGFloat
    let rollDistance: CGFloat

    private var lettersA: [String] { wordA.map(String.init) }
    private var lettersB: [String] { wordB.map(String.init) }
    private var slotCount: Int { max(lettersA.count, lettersB.count) }
    private var widestWord: String { wordA.count >= wordB.count ? wordA : wordB }

    var body: some View {
        // Invisible widest word reserves the slot width; the rolling letters
        // render in an overlay so height stays fixed and clips cleanly.
        Text(verbatim: widestWord)
            .font(font)
            .lineLimit(1)
            .fixedSize()
            .opacity(0)
            .overlay(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0..<slotCount, id: \.self) { index in
                        RollingLetter(
                            letterA: letter(at: index, in: lettersA),
                            letterB: letter(at: index, in: lettersB),
                            showingB: showingB,
                            index: index,
                            font: font,
                            color: color,
                            height: height,
                            rollDistance: rollDistance
                        )
                    }
                }
            }
            .frame(height: height)
            .clipped()
            .animation(RollConfig.animation, value: showingB)
            .accessibilityHidden(true)
    }

    private func letter(at index: Int, in letters: [String]) -> String? {
        letters.indices.contains(index) ? letters[index] : nil
    }
}

// MARK: - Single rolling slot

private struct RollingLetter: View {
    let letterA: String?
    let letterB: String?
    let showingB: Bool
    let index: Int

    let font: Font
    let color: Color
    let height: CGFloat
    let rollDistance: CGFloat

    var body: some View {
        ZStack {
            if showingB, let letterB {
                glyph(letterB)
                    .transition(.asymmetric(
                        insertion: roll(offsetY: rollDistance,  rotation: -28),
                        removal:   roll(offsetY: rollDistance,  rotation: 28)
                    ))
            } else if let letterA {
                glyph(letterA)
                    .transition(.asymmetric(
                        insertion: roll(offsetY: -rollDistance, rotation: 28),
                        removal:   roll(offsetY: -rollDistance, rotation: -28)
                    ))
            }
        }
        .frame(height: height)
        .clipped()
        .animation(RollConfig.letterAnimation(index: index), value: showingB)
    }

    private func glyph(_ text: String) -> some View {
        Text(verbatim: text)
            .font(font)
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    private func roll(offsetY: CGFloat, rotation: Double) -> AnyTransition {
        .modifier(
            active: RollModifier(offsetY: offsetY, rotation: rotation, opacity: 0, blurRadius: RollConfig.blur),
            identity: RollModifier(offsetY: 0, rotation: 0, opacity: 1, blurRadius: 0)
        )
    }
}
