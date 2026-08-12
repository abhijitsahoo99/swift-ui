//
//  FeeDetailsTab.swift
//  sliderSwift
//
//  Figma node 12242:20412 — a 306pt tab with only its top corners rounded,
//  sitting flush on top of the slide bar.
//

import SwiftUI

struct FeeDetailsTab: View {
    let feePercent: Double
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Text("Fee & Details")
                    .figmaStyle(Theme.subheadline, tracking: Theme.subheadlineTracking, color: Theme.labelSecondary)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    Text(String(format: "%.2f%%", feePercent))
                        .figmaStyle(Theme.subheadline, tracking: Theme.subheadlineTracking, color: Theme.gray)

                    Image(.caretUp)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13.33, height: 7.72)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(width: 306)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16,
                    style: .continuous
                )
                .fill(Theme.gray6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fee and details, \(String(format: "%.2f", feePercent)) percent")
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        FeeDetailsTab(feePercent: 0.12) {}
    }
    .preferredColorScheme(.dark)
}
