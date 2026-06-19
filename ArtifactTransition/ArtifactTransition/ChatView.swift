//
//  ChatView.swift
//  ArtifactTransition
//
//  The chat screen (screenshot #1). The artifact preview is an
//  `ArtifactCardTransition` — tap it and it morphs open into the full
//  document; drag it down (or tap the top-left X) to collapse back here.
//

import SwiftUI

struct ChatView: View {
    var body: some View {
        ZStack {
            Art.chatBG.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("…arily about the protocol's value, not clearly about the token. Buy on token-cash-flow, not narrative. I'd stay cautious on MORPHO, ENA until token capture mechanics get explicit.")
                        .foregroundStyle(.white.opacity(0.92))

                    Text("Tiny banker stamp: great protocols can still be bad buys if the token does not capture the economics.")
                        .foregroundStyle(.white.opacity(0.92))

                    artifactBlock

                    fileBlock

                    actionRow
                        .padding(.top, 2)
                }
                .font(.system(size: 17))
                .lineSpacing(3)
                .padding(.horizontal, 18)
                .padding(.top, 64)
                .padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) { inputBar }
    }

    // MARK: Artifact preview + caption

    private var artifactBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            ArtifactCardTransition { isExpanded, _ in
                ArtifactHeader(isExpanded: isExpanded)
            } content: { safeArea, _ in
                ArtifactBody(safeArea: safeArea)
            }
            .frame(height: 234)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Art.artifactBG],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 72)
                .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: 26))

            HStack {
                Text("Crypto DCF analyst screen")
                Spacer()
                Image(systemName: "arrow.down.to.line")
            }
            .font(.system(size: 15))
            .foregroundStyle(Art.subtle)
            .padding(.horizontal, 4)
        }
    }

    // MARK: CSV attachment

    private var fileBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(white: 0.16))
                    Text("CSV")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.pink)
                        .offset(y: 9)
                }
                .frame(width: 34, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("crypto-dcf-model.csv")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    Text("text/csv · 6 KB")
                        .font(.system(size: 14))
                        .foregroundStyle(Art.subtle)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.down.to.line")
                    .foregroundStyle(Art.subtle)
            }
            .padding(14)
            .background(Art.surface.opacity(0.55), in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Art.hairline, lineWidth: 1))

            Text("DCF model CSV")
                .font(.system(size: 14))
                .foregroundStyle(Art.subtle)
                .padding(.leading, 4)
        }
    }

    // MARK: Reaction row

    private var actionRow: some View {
        HStack(spacing: 26) {
            Image(systemName: "square.on.square")
            Image(systemName: "hand.thumbsup")
            Image(systemName: "hand.thumbsdown")
            Image(systemName: "arrow.clockwise")
        }
        .font(.system(size: 19))
        .foregroundStyle(Art.subtle)
        .padding(.leading, 2)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            circleButton("xmark")

            Spacer()

            HStack(spacing: 6) {
                Text("Agent")
                    .font(.system(size: 17, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Capsule().fill(Art.surface.opacity(0.7)))
            .overlay(Capsule().stroke(Art.hairline, lineWidth: 1))

            Spacer()

            circleButton("ellipsis")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background {
            LinearGradient(
                colors: [Art.chatBG, Art.chatBG, Art.chatBG.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            circleButton("plus")

            HStack {
                Text("Message Suzi…")
                    .foregroundStyle(Art.subtle)
                Spacer()
                Image(systemName: "mic.fill")
                    .foregroundStyle(Art.subtle)
            }
            .font(.system(size: 17))
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Capsule().fill(Art.surface.opacity(0.7)))
            .overlay(Capsule().stroke(Art.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background {
            LinearGradient(
                colors: [Art.chatBG.opacity(0), Art.chatBG, Art.chatBG],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func circleButton(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(Circle().fill(Art.surface.opacity(0.7)))
            .overlay(Circle().stroke(Art.hairline, lineWidth: 1))
    }
}

#Preview {
    ChatView()
        .preferredColorScheme(.dark)
}
