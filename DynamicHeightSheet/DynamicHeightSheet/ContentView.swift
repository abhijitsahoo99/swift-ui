//
//  ContentView.swift
//  DynamicHeightSheet
//
//  Created by Balaji Venkatesh on 31/08/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showTrayView: Bool = false
    var body: some View {
        ZStack {
            WalletBackgroundView()

            // Blur overlay when tray is open
            if showTrayView {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    showTrayView.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .padding(.trailing, 20)
            .padding(.top, 10)
        }
        .sheet(isPresented: $showTrayView) {
            let animation: Animation = .snappy(duration: 0.3, extraBounce: 0)
            DynamicSheet(animation: animation) {
                TrayView(animation: animation)
            }
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Wallet Background View

struct WalletBackgroundView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top section
                VStack(spacing: 16) {
                    // Wallet header
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.blue.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Image(systemName: "globe")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            Text("Main Wallet")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Net Worth Card
                    VStack(spacing: 8) {
                        Text("Net Worth")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$1,456")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                            Text(".23")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        HStack(spacing: 12) {
                            AddressPill(text: "3Infr...fecg")
                            AddressPill(text: "0x0b...0901")
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.pink.opacity(0.7), .pink.opacity(0.4), .pink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.horizontal, 20)

                    // Positions & Orders
                    HStack(spacing: 12) {
                        InfoCard(title: "Positions", value: "$1,298,63.5", icons: ["circle.fill", "circle.fill", "circle.fill"])
                        InfoCard(title: "Orders", value: "$1,298,63.5", icons: ["circle.fill", "circle.fill", "circle.fill"])
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 10)

                // Holdings section
                VStack(spacing: 0) {
                    HStack {
                        Text("Holdings")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("$13,789")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .padding(.bottom, 16)

                    // Token rows
                    VStack(spacing: 0) {
                        HoldingRow(image: "usdc", name: "USDC", amount: "836.92 USDC", value: "$836.92", change: "+5.4%", isPositive: true)
                        HoldingRow(image: "usdc", name: "USDC.e", amount: "263.5 USDC.e", value: "$263.5", change: "-6.4%", isPositive: false)
                        HoldingRow(image: "sol", name: "SOL", amount: "1.2K SOL", value: "$205.81", change: "+5.4%", isPositive: true)
                        HoldingRow(image: "eth", name: "ETH", amount: "0.12 ETH", value: "$150.25", change: "+3.2%", isPositive: true)
                        HoldingRow(image: "sol", name: "SOL", amount: "0.5 SOL", value: "$150.25", change: "+3.2%", isPositive: true)
                        HoldingRow(image: "eth", name: "ETH", amount: "0.08 ETH", value: "$120.00", change: "-1.2%", isPositive: false)
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Supporting Views

struct AddressPill: View {
    var text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 9))
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.2), in: .capsule)
    }
}

struct InfoCard: View {
    var title: String
    var value: String
    var icons: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: -6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill([Color.purple, .blue, .orange][i])
                        .frame(width: 20, height: 20)
                        .overlay {
                            Circle().stroke(.white, lineWidth: 1.5)
                        }
                }
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
    }
}

struct HoldingRow: View {
    var image: String
    var name: String
    var amount: String
    var value: String
    var change: String
    var isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(.circle)
                .background {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 36, height: 36)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(amount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(change)
                    .font(.caption)
                    .foregroundStyle(isPositive ? .green : .red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

#Preview {
    ContentView()
}
