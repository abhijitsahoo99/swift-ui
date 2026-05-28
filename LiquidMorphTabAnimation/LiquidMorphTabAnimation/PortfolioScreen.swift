//
//  PortfolioScreen.swift
//  LiquidMorphTabAnimation
//
//  Static copy of suzi-swift's TopPaneSummaryView (.cards mode) + HoldingsListView,
//  the actual portfolio home screen. No networking — dummy data. Custom image assets
//  (wallet/avatar/chain/token logos) are substituted with gradient/SF placeholders.
//

import SwiftUI
import UIKit

// MARK: - Dummy data

private enum Mock {
    static let accountName = "justabhi99"
    static let netWorth: Double = 67.82
    static let solAddress = "4CJJ8wXXXXXXXXByg3"   // shows as 4CJJ....Byg3
    static let evmAddress = "0xF2XXXXXXXXXX3E25"    // shows as 0xF2....3E25
    static let positionsValue: Double = 0.55
    static let holdingsTotal: Double = 67.26

    enum LogoKind { case usdc, sol, cloud }       // how to render the main token logo
    enum ChainBadge { case solana, evm, hyperliquid }   // which suzi chain asset to overlay

    struct Holding: Identifiable {
        let id = UUID()
        let name: String
        let amount: String
        let value: Double
        let change: Double
        let logo: LogoKind
        let chain: ChainBadge
    }

    /// Values mirror the real app's portfolio screenshot.
    static let holdings: [Holding] = [
        .init(name: "USDCE",        amount: "25.5 USDCE",  value: 25.48, change:  0.02, logo: .usdc,  chain: .evm),
        .init(name: "USDC",         amount: "20.67 USDC",  value: 20.66, change:  0.01, logo: .usdc,  chain: .solana),
        .init(name: "SOL",          amount: "0.2302 SOL",  value: 18.62, change: -3.48, logo: .sol,   chain: .solana),
        .init(name: "USDC (Perps)", amount: "2.48 USDC",   value:  2.48, change: -0.30, logo: .usdc,  chain: .hyperliquid),
        .init(name: "CLOUD",        amount: "0.8 CLOUD",   value:  0.02, change: -3.59, logo: .cloud, chain: .solana),
    ]
}

// MARK: - Screen

struct PortfolioScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                headerBar

                VStack(spacing: Spacing.sm) {
                    netWorthCard.padding(.horizontal, Spacing.xs)
                    walletAddressPills.padding(.bottom, Spacing.sm)
                }
                .padding(.top, Spacing.xs)
                .background { RoundedRectangle(cornerRadius: 38).fill(Color.backgroundSecondary) }
                .padding(.horizontal, Spacing.lg)

                positionsOrdersCards.padding(.top, Spacing.xs)

                grabber.padding(.vertical, Spacing.sm)

                HoldingsList()
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, 140)   // clearance for the floating dock
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: header
    private var headerBar: some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Image("WalletIcon1")
                    .resizable().scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                Text(Mock.accountName)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .tracking(-0.26)
                    .foregroundColor(.textPrimary)
                Image("ChevronDown")
                    .renderingMode(.template).resizable().scaledToFit()
                    .frame(width: 11, height: 7)
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(width: 34, height: 34)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
            Image("Pfpfallback")
                .resizable().scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
        }
        .padding(.horizontal, 24)
    }

    // MARK: net worth card
    private var netWorthCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Net Worth")
                .font(Typography.title3).tracking(-0.26)
                .foregroundColor(.white)
            rawBalanceText(value: Mock.netWorth)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.lg)
        .background { NetWorthCardGradientBackground(cornerRadius: 34) }
    }

    private static let balanceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.decimalSeparator = "."
        f.groupingSeparator = ","
        return f
    }()

    private func rawBalanceText(value: Double) -> Text {
        let number = Self.balanceFormatter.string(from: NSNumber(value: abs(value))) ?? String(format: "%.2f", value)
        let formatted = "$\(number)"
        if let dot = formatted.range(of: ".")?.lowerBound {
            let intPart = String(formatted[formatted.startIndex..<dot])
            let decPart = String(formatted[dot...])
            return Text(intPart).font(Typography.balance).tracking(Typography.balanceTracking)
                + Text(decPart).font(Typography.balanceFraction).tracking(Typography.balanceFractionTracking)
        }
        return Text(formatted).font(Typography.balance).tracking(Typography.balanceTracking)
    }

    // MARK: wallet pills
    private var walletAddressPills: some View {
        HStack(spacing: Spacing.md) {
            addressPill(asset: "SolanaChainIcon", iconSize: CGSize(width: 15, height: 12), address: Mock.solAddress,
                        tint: Colors.walletBluePurple, bg: Colors.walletBluePurple.opacity(0.16))
            addressPill(asset: "EvmChainIcon", iconSize: CGSize(width: 10, height: 15), address: Mock.evmAddress,
                        tint: Colors.walletBlue, bg: Colors.walletBlue.opacity(0.16))
        }
        .padding(.vertical, Spacing.xs)
    }

    private func addressPill(asset: String, iconSize: CGSize, address: String, tint: Color, bg: Color) -> some View {
        let truncated = "\(address.prefix(4))....\(address.suffix(4))"
        return HStack(spacing: Spacing.xsm) {
            Image(asset).renderingMode(.original).resizable().scaledToFit()
                .frame(width: iconSize.width, height: iconSize.height)
            Text(truncated).font(.labelMedium).tracking(-0.08).foregroundColor(tint)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xsm)
        .frame(height: 34)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 34))
    }

    // MARK: positions / orders
    private var positionsOrdersCards: some View {
        HStack(spacing: Spacing.lg) {
            summaryTile(title: "Positions", valueText: Fmt.fiat(Mock.positionsValue),
                        protocolColors: [Color(hex: "#0088FF")], gradientColor: Color(hex: "#0088FF"))
            summaryTile(title: "Orders", valueText: "No Active Orders",
                        protocolColors: [], gradientColor: Color(hex: "#34C759"))
        }
        .padding(.horizontal, 16)
    }

    private func summaryTile(title: String, valueText: String, protocolColors: [Color], gradientColor: Color) -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text(title).font(Typography.title3).tracking(-0.26).foregroundColor(.surfaceTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right").font(Typography.iconSmall).foregroundColor(.surfaceTextPrimary)
                }
                HStack(spacing: -9) {
                    ForEach(protocolColors.indices, id: \.self) { i in
                        Circle().fill(protocolColors[i]).frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color(hex: "#1C201D"), lineWidth: 2))
                    }
                }
                .frame(height: protocolColors.isEmpty ? 0 : 24)
            }
            Spacer()
            Text(valueText)
                .font(valueText.hasPrefix("$") ? Typography.title3 : Typography.bodyMedium)
                .foregroundColor(valueText.hasPrefix("$") ? .surfaceTextPrimary : .textMuted)
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 34).fill(Color.surfaceRaised)
                RoundedRectangle(cornerRadius: 34)
                    .fill(RadialGradient(colors: [gradientColor.opacity(0.05), Color.black.opacity(0.05)],
                                         center: UnitPoint(x: 0.4972, y: 0.0728), startRadius: 0, endRadius: 120))
            }
        }
    }

    private var grabber: some View {
        Capsule().fill(Color(hex: "#CCCCCC").opacity(0.4)).frame(width: 36, height: 5)
    }
}

// MARK: - Net Worth pink gradient (copied verbatim from suzi-swift)

private enum NetWorthCardGradientSpec {
    static let designWidth: CGFloat = 362
    static let designHeight: CGFloat = 112
    static let gradientRadius: CGFloat = 10
    static let gradientTransform = CGAffineTransform(a: -5.2957, b: 11.036, c: -33.773, d: -9.9442, tx: 162.96, ty: 60.985)
    static let stops: [(CGFloat, UIColor)] = [
        (0.25481, UIColor(red: 1.0, green: 77.0/255.0,  blue: 169.0/255.0, alpha: 1.0)),
        (0.51866, UIColor(red: 1.0, green: 39.0/255.0,  blue: 140.0/255.0, alpha: 1.0)),
        (0.65059, UIColor(red: 1.0, green: 19.0/255.0,  blue: 126.0/255.0, alpha: 1.0)),
        (0.71656, UIColor(red: 1.0, green: 10.0/255.0,  blue: 118.0/255.0, alpha: 1.0)),
        (0.78252, UIColor(red: 1.0, green: 0.0,         blue: 111.0/255.0, alpha: 1.0)),
        (0.80970, UIColor(red: 1.0, green: 19.0/255.0,  blue: 124.0/255.0, alpha: 1.0)),
        (0.83689, UIColor(red: 1.0, green: 38.0/255.0,  blue: 137.0/255.0, alpha: 1.0)),
        (0.89126, UIColor(red: 1.0, green: 77.0/255.0,  blue: 163.0/255.0, alpha: 1.0)),
        (0.94563, UIColor(red: 1.0, green: 115.0/255.0, blue: 188.0/255.0, alpha: 1.0)),
        (1.0,     UIColor(red: 1.0, green: 153.0/255.0, blue: 214.0/255.0, alpha: 1.0)),
    ]
}

private struct NetWorthCardGradientBackground: View {
    let cornerRadius: CGFloat
    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.withCGContext { cg in
                cg.saveGState()
                cg.addPath(UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath)
                cg.clip()
                let colors = NetWorthCardGradientSpec.stops.map { $0.1.cgColor } as CFArray
                let locations = NetWorthCardGradientSpec.stops.map { $0.0 }
                guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                                colors: colors, locations: locations) else {
                    cg.restoreGState(); return
                }
                cg.concatenate(CGAffineTransform(scaleX: rect.width / NetWorthCardGradientSpec.designWidth,
                                                 y: rect.height / NetWorthCardGradientSpec.designHeight))
                cg.concatenate(NetWorthCardGradientSpec.gradientTransform)
                cg.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0,
                                      endCenter: .zero, endRadius: NetWorthCardGradientSpec.gradientRadius,
                                      options: [.drawsAfterEndLocation])
                cg.restoreGState()
            }
        }
    }
}

// MARK: - Holdings (copied from HoldingsListView)

struct HoldingsList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Holdings").font(Typography.title3).tracking(-0.26).foregroundColor(.textPrimary)
                Spacer()
                Text(Fmt.fiat(Mock.holdingsTotal)).font(Typography.title3).tracking(-0.26).foregroundColor(.textPrimary)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xsm)

            LazyVStack(spacing: Spacing.xl) {
                ForEach(Mock.holdings) { row($0) }
            }
            .padding(.vertical, Spacing.sm)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 34).fill(Color.appBackground))
    }

    private func row(_ h: Mock.Holding) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                tokenLogo(h.logo)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                chainBadge(h.chain)
                    .frame(width: 18, height: 18)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.appBackground).frame(width: 22, height: 22))
                    .offset(x: 2, y: 2)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(h.name).font(Typography.bodySemibold17).tracking(-0.26).foregroundColor(.textPrimary)
                Text(h.amount).font(.bodyMedium).tracking(-0.23).foregroundColor(.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(Fmt.fiat(h.value)).font(.bodyLarge).tracking(-0.26).foregroundColor(.textPrimary)
                Text(Fmt.percent(h.change, signed: true)).font(.bodyMedium).tracking(-0.23)
                    .foregroundColor(h.change >= 0 ? .accentGreen : .accentRed)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Token logos & chain badges

/// USDC-style stablecoin logo: blue ring + white interior + blue $ glyph.
private struct USDCLogo: View {
    private let usdcBlue = Color(hex: "#2775CA")
    var body: some View {
        ZStack {
            Circle().fill(usdcBlue)
            Circle().fill(Color.white).padding(5)
            Text("$").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(usdcBlue)
        }
    }
}

@ViewBuilder
private func tokenLogo(_ kind: Mock.LogoKind) -> some View {
    switch kind {
    case .usdc:
        USDCLogo()
    case .sol:
        Image("SolLogo").resizable().scaledToFill()
    case .cloud:
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(hex: "#1E40AF"), Color(hex: "#0EA5E9")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("C").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }
    }
}

@ViewBuilder
private func chainBadge(_ chain: Mock.ChainBadge) -> some View {
    switch chain {
    case .solana:      Image("SolanaChainIcon").renderingMode(.original).resizable().scaledToFit()
    case .evm:         Image("EvmChainIcon").renderingMode(.original).resizable().scaledToFit()
    case .hyperliquid: Image("Hyperliquid").renderingMode(.original).resizable().scaledToFit()
    }
}

#Preview { PortfolioScreen() }
