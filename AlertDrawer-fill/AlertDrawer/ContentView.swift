//
//  ContentView.swift
//  AlertDrawer
//
//  Created by Balaji Venkatesh on 30/03/25.
//

import SwiftUI

struct ContentView: View {
    @State private var config: DrawerConfig = .init(
        tint: Color(hex: 0xFF4DA9),
        foreground: .white,
        clipShape: .init(.capsule)
    )
    @State private var amount: String = "12.23"
    @State private var address: String = ""
    @State private var withdrawPercentage: Double = 44

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Drag Handle
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            // MARK: - Title
            Text("Withdraw")
                .font(.title3.bold())
                .padding(.top, 12)
                .padding(.bottom, 20)

            // MARK: - Amount Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image("Image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)

                    Text(amount.isEmpty ? "0" : amount)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    // USDC Selector
                    HStack(spacing: 4) {
                        Text("USDC")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5), in: Capsule())
                }

                HStack {
                    Text("$12.34")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("56.54 USDC")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            // MARK: - Address Field
            HStack {
                Text(address.isEmpty ? "HyperEVM Address" : address)
                    .foregroundStyle(address.isEmpty ? Color(.placeholderText) : .primary)
                    .font(.body)

                Spacer()

                Button { } label: {
                    Image(systemName: "doc.on.clipboard")
                        .foregroundStyle(.secondary)
                }

                Button { } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            // MARK: - Withdraw Percentage
            VStack(spacing: 8) {
                HStack {
                    Text("Withdraw")
                        .font(.subheadline)
                    Text("\(Int(withdrawPercentage))%")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Button {
                        withdrawPercentage = 100
                    } label: {
                        Text("Max")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(hex: 0xFF4DA9))
                    }
                }

                // Custom slider track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: 0xFF4DA9),
                                        Color(hex: 0xFF7DC2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (withdrawPercentage / 100), height: 6)

                        // Thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 22, height: 22)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .offset(x: max(0, min(geo.size.width - 22, geo.size.width * (withdrawPercentage / 100) - 11)))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let pct = value.location.x / geo.size.width * 100
                                        withdrawPercentage = min(100, max(0, pct))
                                    }
                            )
                    }
                }
                .frame(height: 22)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // MARK: - Number Pad
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["1","2","3","4","5","6","7","8","9",".","0","←"], id: \.self) { key in
                    Button {
                        handleKeyPress(key)
                    } label: {
                        Text(key)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // MARK: - Withdraw Button
            DrawerButton(title: "Withdraw", config: $config)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .alertDrawer(config: $config, primaryTitle: "Withdraw", secondaryTitle: "Cancel") {
            return false
        } onSecondaryClick: {
            return true
        } content: {
            VStack(alignment: .leading, spacing: 15) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Confirm Withdrawal")
                    .font(.title2.bold())

                Text("You are about to withdraw \(amount.isEmpty ? "0" : amount) USDC to the specified HyperEVM address. Please verify the address is correct — this action cannot be undone.")
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300)
            }
        }
    }

    private func handleKeyPress(_ key: String) {
        switch key {
        case "←":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case ".":
            if !amount.contains(".") {
                amount.append(".")
            }
        default:
            if amount == "0" {
                amount = key
            } else {
                amount.append(key)
            }
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

#Preview {
    ContentView()
}
