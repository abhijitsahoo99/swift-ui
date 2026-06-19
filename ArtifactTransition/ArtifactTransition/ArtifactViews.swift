//
//  ArtifactViews.swift
//  ArtifactTransition
//
//  The artifact content, split the way the transition engine wants it:
//  `ArtifactHeader` is the hero that morphs between the chat card preview and
//  the top of the open document; `ArtifactBody` is everything revealed below
//  on expand.
//

import SwiftUI

// MARK: - Palette

enum Art {
    static let chatBG     = Color(white: 0.09)          // chat surface
    static let artifactBG = Color(white: 0.035)         // card / open document
    static let surface    = Color(white: 0.13)          // chips, file rows
    static let hairline   = Color.white.opacity(0.09)
    static let subtle     = Color(white: 0.55)
    static let gold       = Color(red: 0.80, green: 0.72, blue: 0.46)
}

// MARK: - Hero (shared morphing element)

struct ArtifactHeader: View {
    var isExpanded: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Art.artifactBG

            // Top-aligned with fixed spacing (no flexible Spacer — a flexible
            // spacer can resolve negative while the hero height interpolates
            // during the morph, which feeds NaN to the child shape layers).
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    ThemeSegmentedControl()
                }

                Text("Crypto DCF Analyst Screen")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, isExpanded ? 30 : 20)

                Text("Generated 2026-06-19 09:01 UTC · DefiLlama revenue + CoinPaprika market data · strict token-cash-flow model")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Art.subtle)
                    .lineSpacing(2)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 22)
            .padding(.top, isExpanded ? 60 : 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - AUTO / DARK / LIGHT (visual only)

struct ThemeSegmentedControl: View {
    private let options = ["AUTO", "DARK", "LIGHT"]
    private let selected = "AUTO"

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Text(option)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(option == selected ? .white : Art.subtle)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 13)
                    .background {
                        if option == selected {
                            Capsule().fill(Color(white: 0.24))
                        }
                    }
            }
        }
        .padding(3)
        .background(Capsule().fill(Color(white: 0.12)))
        .overlay(Capsule().stroke(Art.hairline, lineWidth: 1))
    }
}

// MARK: - Body (revealed on expand)

struct ArtifactBody: View {
    var safeArea: EdgeInsets

    private let chips: [(String, String)] = [
        ("DCF horizon:", "5 years"),
        ("Discount rates:", "20–34%"),
        ("Terminal growth:", "3%"),
        ("Buy zone:", "30% margin of safety")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Chips + main read, in one bordered card
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(chips, id: \.0) { label, value in
                        Chip(label: label, value: value)
                    }
                }

                MainReadCallout()
            }
            .padding(18)
            .background(Art.artifactBG, in: .rect(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Art.hairline, lineWidth: 1))

            // Watchlist card
            VStack(alignment: .leading, spacing: 12) {
                Text("Relative-value watchlist")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Art.subtle)

                Text("LDO, GMX, AERO, SKY, AAVE")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Art.artifactBG, in: .rect(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Art.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, safeArea.bottom + 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Art.artifactBG)
    }

    private func Chip(label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundStyle(Art.subtle)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .font(.system(size: 15))
        .padding(.vertical, 9)
        .padding(.horizontal, 15)
        .background(Capsule().fill(Color(white: 0.10)))
        .overlay(Capsule().stroke(Art.hairline, lineWidth: 1))
    }

    private func MainReadCallout() -> some View {
        Text("**Main read:** strict DCF says almost every major token is expensive versus distributable token cash flow. The relative value bucket is not a table-pounding buy list; it is the least-bad watchlist for deep drawdowns.")
        .font(.system(size: 16))
        .foregroundStyle(Art.gold)
        .lineSpacing(3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Art.gold.opacity(0.07), in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Art.gold.opacity(0.45), lineWidth: 1))
    }
}
