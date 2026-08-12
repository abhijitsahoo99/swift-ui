//
//  Numpad.swift
//  sliderSwift
//
//  Figma node 12242:20339 ("numbers") — 4 rows of 3, 52pt tall, 12pt gaps.
//  Keys have no resting fill in the design; the tap feedback is a brief tint.
//

import SwiftUI
import UIKit

struct Numpad: View {
    @Binding var entry: AmountEntry

    /// The key shows what the user's own region writes — a comma on a French
    /// or German device. What `AmountEntry` stores is a dot either way.
    private var separator: String { Locale.current.decimalSeparator ?? "." }

    private let rows: [[Key]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.dot, .digit("0"), .backspace]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 12) {
                    ForEach(row) { key in
                        NumpadKey(key: key, separator: separator) { press(key) }
                    }
                }
                .frame(height: 52)
            }
        }
    }

    private func press(_ key: Key) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        /// Every rule about what may be typed — decimal places, digit count,
        /// leading zeros — lives on `AmountEntry`, so it holds wherever the
        /// value is edited from and can be tested without a view.
        switch key {
        case .backspace: entry.deleteBackward()
        case .dot: entry.appendSeparator()
        case .digit(let d): entry.append(digit: Character(d))
        }
    }

    enum Key: Identifiable, Hashable {
        case digit(String)
        case dot
        case backspace

        var id: String {
            switch self {
            case .digit(let d): d
            case .dot: "separator"
            case .backspace: "backspace"
            }
        }

        func label(separator: String) -> String {
            switch self {
            case .digit(let d): d
            case .dot: separator
            case .backspace: "←"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .digit(let d): d
            case .dot: "Decimal point"
            case .backspace: "Delete"
            }
        }
    }
}

private struct NumpadKey: View {
    let key: Numpad.Key
    let separator: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(key.label(separator: separator))
                .figmaStyle(Theme.title1, tracking: Theme.title1Tracking, color: Theme.grayWhite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(Color.white.opacity(isPressed ? 0.08 : 0))
                }
                .contentShape(.rect(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(key.accessibilityLabel)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

#Preview {
    @Previewable @State var value = AmountEntry("126.89")

    ZStack {
        Theme.background.ignoresSafeArea()
        Numpad(entry: $value)
            .padding(.horizontal, 24)
    }
    .preferredColorScheme(.dark)
}
