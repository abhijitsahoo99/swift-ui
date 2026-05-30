//
//  HoldingsRow.swift
//  xSidebarAnimation
//

import SwiftUI

struct HoldingsRow: View {
    let holding: DummyHolding

    var body: some View {
        HStack(spacing: 12) {
            tokenLogo

            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(holding.detail)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.usdValue)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(holding.changePercent)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(holding.isPositive ? .successGreen : .errorRed)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var tokenLogo: some View {
        ZStack {
            Circle()
                .fill(holding.logoTint.opacity(0.25))
            Circle()
                .stroke(holding.logoTint.opacity(0.6), lineWidth: 1)
            Text(String(holding.symbol.prefix(1)))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
    }
}
