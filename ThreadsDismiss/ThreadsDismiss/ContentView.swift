//
//  ContentView.swift
//  ThreadsDismiss
//
//  Created by Abhijit Sahoo on 01/04/26.
//

import SwiftUI

// MARK: - Data Model

struct MarketPosition: Identifiable {
    let id = UUID()
    let question: String
    let side: String
    let price: String
    let change: String
    let value: String

    var isYes: Bool { side == "YES" }
    var changeIsPositive: Bool { change.hasPrefix("+") }
}

struct Holding: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let value: String
    let change: String
    var changeIsPositive: Bool { change.hasPrefix("+") }
}

// MARK: - Main Home Page

struct ContentView: View {
    private let holdings: [Holding] = [
        .init(name: "USDC", subtitle: "836.92 USDC", value: "$836.92", change: "+5.4%"),
        .init(name: "USDC.e", subtitle: "263.5 USDC.e", value: "$263.5", change: "-5.4%"),
        .init(name: "JUP", subtitle: "1.2K JUP", value: "$205.81", change: "+5.4%"),
        .init(name: "PENGU", subtitle: "4.8K PENGU", value: "$150.25", change: "-2.8%"),
        .init(name: "SPLAT", subtitle: "1.8K SPLAT", value: "$98.50", change: "+3.2%"),
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        // Top bar
                        HStack(spacing: 12) {
                            // Wallet icon
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.55, green: 0.4, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                )

                            Text("Main Wallet")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                                .foregroundStyle(.secondary)

                            Image("trump")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                        // Net Worth Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Net Worth")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))

                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("$1,456")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(".23")
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.45, blue: 0.55),
                                    Color(red: 0.98, green: 0.35, blue: 0.6),
                                    Color(red: 1.0, green: 0.5, blue: 0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 16)

                        // Address chips
                        HStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.on.square")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(red: 0.13, green: 0.59, blue: 0.33))
                                Text("3nfr....fecg")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.13, green: 0.59, blue: 0.33))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.13, green: 0.59, blue: 0.33).opacity(0.08), in: Capsule())

                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(red: 0.3, green: 0.36, blue: 0.86))
                                Text("0x6b...0901")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.3, green: 0.36, blue: 0.86))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.3, green: 0.36, blue: 0.86).opacity(0.08), in: Capsule())

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                        // Positions & Orders cards
                        HStack(spacing: 12) {
                            // Positions card
                            NavigationLink {
                                PositionsView()
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Positions")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    // Stacked protocol icons
                                    HStack(spacing: -8) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.orange, Color(red: 0.9, green: 0.5, blue: 0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Image(systemName: "mountain.2.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(.white)
                                            )

                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(red: 0.3, green: 0.36, blue: 0.86), Color(red: 0.22, green: 0.28, blue: 0.78)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Image(systemName: "chart.bar.fill")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(.white)
                                            )
                                    }

                                    Text("$216.81")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                }
                                .padding(16)
                                .background(Color(red: 0.95, green: 0.95, blue: 0.955), in: RoundedRectangle(cornerRadius: 16))
                            }

                            // Orders card
                            Button {
                                // Orders action
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Orders")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }

                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.teal, Color(red: 0.1, green: 0.6, blue: 0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        )

                                    Text("$139")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                }
                                .padding(16)
                                .background(Color(red: 0.95, green: 0.95, blue: 0.955), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        // Holdings section
                        VStack(spacing: 0) {
                            HStack {
                                Text("Holdings")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Spacer()
                                Text("$1,152")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .padding(.bottom, 8)

                            ForEach(holdings) { holding in
                                HoldingRow(holding: holding)
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)

                // Home Bottom Tab Bar
                HomeTabBar()
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Holding Row

struct HoldingRow: View {
    let holding: Holding

    private var changeColor: Color {
        holding.changeIsPositive
            ? Color(red: 0.13, green: 0.59, blue: 0.33)
            : Color(red: 0.88, green: 0.17, blue: 0.22)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image("usdc")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(holding.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(holding.subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(holding.value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(holding.change)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(changeColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Home Tab Bar

struct HomeTabBar: View {
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20))
                    Text("Trade")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                .frame(width: 72)
                .padding(.vertical, 10)

                VStack(spacing: 3) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                    Text("Agents")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color(red: 0.7, green: 0.7, blue: 0.7))
                .frame(width: 72)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
            )

            Spacer()

            // Plus button
            Button {
                //
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.pink)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(Color.pink.opacity(0.08))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            Color.white
                .opacity(0.001) // invisible but captures taps
        )
    }
}

// MARK: - Positions View

struct PositionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isNearBottom = false

    private let positions: [MarketPosition] = [
        .init(question: "Will Trump release the Epstein files by November 30?", side: "YES", price: "80\u{00A2}", change: "-5.4%", value: "$263.5"),
        .init(question: "Will Trump release the Epstein files by November 30?", side: "NO", price: "80\u{00A2}", change: "-5.4%", value: "$263.5"),
        .init(question: "Will Bitcoin reach $100K by December 2026?", side: "YES", price: "62\u{00A2}", change: "+12.3%", value: "$450.0"),
        .init(question: "Will the Fed cut interest rates in Q3 2026?", side: "YES", price: "45\u{00A2}", change: "-2.1%", value: "$180.0"),
        .init(question: "Will Tesla stock hit $500 by year end?", side: "NO", price: "73\u{00A2}", change: "+3.8%", value: "$320.5"),
        .init(question: "Will AI replace 10% of jobs by 2027?", side: "YES", price: "34\u{00A2}", change: "-8.2%", value: "$125.0"),
        .init(question: "Will SpaceX land humans on Mars by 2030?", side: "NO", price: "88\u{00A2}", change: "+1.5%", value: "$540.0"),
        .init(question: "Will Apple release AR glasses in 2026?", side: "YES", price: "52\u{00A2}", change: "-4.7%", value: "$210.0"),
        .init(question: "Will Ethereum flip Bitcoin by market cap?", side: "NO", price: "91\u{00A2}", change: "+0.9%", value: "$380.0"),
        .init(question: "Will US enter a recession in 2026?", side: "YES", price: "28\u{00A2}", change: "-6.3%", value: "$95.0"),
    ]

    private let cardBg = Color(red: 0.95, green: 0.95, blue: 0.955)

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // MARK: Sticky Header
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color(red: 0.78, green: 0.78, blue: 0.78))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Centered $13,789 with Positions left & Live right
                    ZStack {
                        // Center — amount
                        Text("$13,789")
                            .font(.system(size: 24, weight: .regular, design: .rounded))
                            .foregroundStyle(Color(red: 0.35, green: 0.35, blue: 0.35))

                        // Left & Right
                        HStack {
                            Text("Positions")
                                .font(.system(size: 24, weight: .bold, design: .rounded))

                            Spacer()

                            HStack(spacing: 5) {
                                Text("Live")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
                .background(
                    Color.white
                        .shadow(.drop(color: .black.opacity(0.04), radius: 6, y: 4))
                )
                .zIndex(1)

                // MARK: Scrollable Content
                ScrollView(.vertical) {
                    VStack(spacing: 12) {
                        // Meteora Card
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.22, green: 0.16, blue: 0.12), Color(red: 0.14, green: 0.1, blue: 0.07)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "mountain.2.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.85))
                                )

                            Text("Meteora")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)

                        // Polymarket Section
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.3, green: 0.36, blue: 0.86), Color(red: 0.22, green: 0.28, blue: 0.78)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "chart.bar.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.85))
                                    )

                                Text("Polymarket")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 0.6))

                                Spacer()

                                Text("$1,263.5")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                                ZStack {
                                    Circle()
                                        .fill(Color.pink.opacity(0.55))
                                        .frame(width: 14, height: 14)
                                        .offset(x: -4)
                                    Circle()
                                        .fill(Color.pink.opacity(0.35))
                                        .frame(width: 14, height: 14)
                                        .offset(x: 4)
                                }
                                .frame(width: 24, height: 14)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            ForEach(Array(positions.enumerated()), id: \.element.id) { index, position in
                                if index > 0 {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                                PositionRow(position: position)
                            }

                            Spacer().frame(height: 8)
                        }
                        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
                .swipeUpToDismiss(120, bottomInset: isNearBottom ? 8 : 80) {
                    dismiss()
                }
                .onScrollGeometryChange(for: Bool.self) {
                    let offset = $0.contentOffset.y + $0.contentInsets.top
                    let contentHeight = $0.contentSize.height
                    let containerHeight = $0.containerSize.height
                    let fromBottom = max(contentHeight - containerHeight, 0) - offset
                    return fromBottom < 0
                } action: { _, newValue in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isNearBottom = newValue
                    }
                }
            }

            // MARK: Floating Bottom Tab Bar — hides near bottom
            PositionsTabBar()
                .padding(.bottom, 8)
                .offset(y: isNearBottom ? 120 : 0)
                .opacity(isNearBottom ? 0 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: isNearBottom)
        }
        .background(Color.white)
        .navigationBarBackButtonHidden()
    }
}

// MARK: - Positions Tab Bar

struct PositionsTabBar: View {
    @State private var selectedTab = 0

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = 0
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 20))
                        Text("Positions")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == 0 ? .pink : Color(red: 0.7, green: 0.7, blue: 0.7))
                    .frame(width: 72)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == 0
                            ? Capsule().fill(Color.pink.opacity(0.1))
                            : Capsule().fill(Color.clear)
                    )
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = 1
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 20))
                        Text("Orders")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == 1 ? .pink : Color(red: 0.7, green: 0.7, blue: 0.7))
                    .frame(width: 72)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == 1
                            ? Capsule().fill(Color.pink.opacity(0.1))
                            : Capsule().fill(Color.clear)
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
            )

            Spacer()

            Button {
                //
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.pink)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(Color.pink.opacity(0.08))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.pink.opacity(0.3), lineWidth: 1.5)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Position Row

struct PositionRow: View {
    let position: MarketPosition

    private var sideColor: Color {
        position.isYes
            ? Color(red: 0.13, green: 0.59, blue: 0.33)
            : Color(red: 0.88, green: 0.17, blue: 0.22)
    }

    private var changeColor: Color {
        position.changeIsPositive
            ? Color(red: 0.13, green: 0.59, blue: 0.33)
            : Color(red: 0.88, green: 0.17, blue: 0.22)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Avatar + Title
            HStack(alignment: .top, spacing: 12) {
                Image("trump")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())

                Text(position.question)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .tracking(-0.26)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
            }

            // Row 2: Side + Price on left, Change + Value on right (full width)
            HStack(alignment: .center) {
                Text("\(position.side) \u{2022} \(position.price)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(sideColor)

                Spacer()

                Text(position.change)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(changeColor)

                Text(position.value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
