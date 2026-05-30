//
//  PortfolioScreen.swift
//  xSidebarAnimation
//
//  Single SwiftUI ScrollView clone of Suzi's TopPaneSummaryView +
//  HoldingsBottomPaneView. No UIKit split-pane.
//

import SwiftUI

struct PortfolioScreen: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerBar
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 14)

                    topPaneCard
                        .padding(.horizontal, 16)

                    positionsOrdersCards
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    grabHandle
                        .padding(.top, 18)
                        .padding(.bottom, 10)

                    holdingsHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    holdingsList

                    Spacer(minLength: 120) // clearance for floating dock
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                avatarCircle(diameter: 34, gradient: [.accentPink, .walletBluePurple])

                Text(DummyUser.handle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .tracking(-0.26)
                    .foregroundColor(.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            Button { } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Color.backgroundSecondary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            avatarCircle(diameter: 34, gradient: [.successGreen, .walletBlue])
        }
    }

    private func avatarCircle(diameter: CGFloat, gradient: [Color]) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: diameter, height: diameter)
    }

    // MARK: - Top pane card (net worth + wallet pills)

    private var topPaneCard: some View {
        VStack(spacing: 12) {
            NetWorthCard(value: DummyUser.netWorth)
                .padding(.horizontal, 4)

            walletAddressPills
                .padding(.bottom, 6)
        }
        .padding(.top, 6)
        .background {
            RoundedRectangle(cornerRadius: 38)
                .fill(Color.backgroundSecondary)
        }
    }

    private var walletAddressPills: some View {
        HStack(spacing: 12) {
            addressPill(
                systemIcon: "circle.hexagongrid.fill",
                address: DummyUser.solanaAddress,
                tint: .walletBluePurple
            )
            addressPill(
                systemIcon: "diamond.fill",
                address: DummyUser.evmAddress,
                tint: .walletBlue
            )
        }
        .padding(.vertical, 4)
    }

    private func addressPill(systemIcon: String, address: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemIcon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(tint)
            Text(address)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(-0.08)
                .foregroundColor(tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(height: 34)
        .background(tint.opacity(0.16))
        .clipShape(Capsule())
    }

    // MARK: - Positions / Orders

    private var positionsOrdersCards: some View {
        HStack(spacing: 14) {
            summaryTile(
                title: "Positions",
                valueText: "$0.55",
                emptyMessage: nil,
                gradientColor: Color(red: 0.0, green: 0.53, blue: 1.0),
                protocolGlyph: "circle.hexagongrid.fill"
            )

            summaryTile(
                title: "Orders",
                valueText: nil,
                emptyMessage: "No Active Orders",
                gradientColor: Color(red: 0.20, green: 0.78, blue: 0.35),
                protocolGlyph: nil
            )
        }
    }

    @ViewBuilder
    private func summaryTile(
        title: String,
        valueText: String?,
        emptyMessage: String?,
        gradientColor: Color,
        protocolGlyph: String?
    ) -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .tracking(-0.26)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }

                if let protocolGlyph {
                    Circle()
                        .fill(Color.walletBluePurple.opacity(0.4))
                        .overlay {
                            Image(systemName: protocolGlyph)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 24, height: 24)
                } else {
                    Color.clear.frame(height: 24)
                }
            }

            Spacer()

            if let emptyMessage {
                Text(emptyMessage)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.56, green: 0.56, blue: 0.56), location: 0.07),
                                .init(color: Color(red: 0.22, green: 0.22, blue: 0.22), location: 1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else if let valueText {
                Text(valueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(Color.surfaceRaised)
                RoundedRectangle(cornerRadius: 34)
                    .fill(
                        RadialGradient(
                            colors: [
                                gradientColor.opacity(0.10),
                                Color.black.opacity(0.05),
                            ],
                            center: UnitPoint(x: 0.5, y: 0.07),
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
            }
        }
    }

    // MARK: - Grab handle

    private var grabHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.5))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Holdings

    private var holdingsHeader: some View {
        HStack {
            Text("Holdings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Spacer()
            Text(DummyHoldings.total)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
        }
    }

    private var holdingsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(DummyHoldings.all) { holding in
                HoldingsRow(holding: holding)
            }
        }
        .padding(.top, 6)
    }
}
