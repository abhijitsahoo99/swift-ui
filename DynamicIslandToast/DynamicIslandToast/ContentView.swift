//
//  ContentView.swift
//  DynamicIslandToast
//
//  Created by Abhijit Sahoo on 31/03/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var showToast: Bool = false
    @State private var selectedNetwork: String = "Solana"

    private let walletAddress = "4g2d....2h3f"
    private let fullAddress = "4g2d7Kx9mNpQrS8tVwYz3bCfHjLnR5uA2h3f"

    var body: some View {
        ZStack {
            // Fake home screen background with blurred content
            VStack(spacing: 0) {
                // Status bar area
                HStack {
                    Spacer()
                }
                .frame(height: 60)

                // Fake wallet header row
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(red: 0.3, green: 0.35, blue: 0.75))
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.3))
                            .frame(width: 80, height: 10)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.5))
                            .frame(width: 50, height: 8)
                    }

                    Spacer()

                    Circle()
                        .fill(Color(white: 0.15))
                        .frame(width: 32, height: 32)
                    Circle()
                        .fill(Color(white: 0.15))
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Pink gradient card placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.55, blue: 0.65),
                                Color(red: 0.95, green: 0.70, blue: 0.75)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 90)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.96))

            // Blur overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Bottom sheet card
            VStack(spacing: 0) {
                // Drag Indicator
                Capsule()
                    .fill(Color(white: 0.78))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)

                // Header
                HStack {
                    Text("Deposit")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.black)

                    Spacer()

                    Button {
                        // Close
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(white: 0.4))
                            .frame(width: 30, height: 30)
                            .background(Color(white: 0.91))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Address Row
                HStack(spacing: 10) {
                    // Solana logo (three horizontal bars)
                    SolanaIcon()
                        .frame(width: 22, height: 18)

                    Text(walletAddress)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(.black)

                    Spacer()

                    // Green network icon
                    NetworkIcon()
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // QR Code
                DotQRCodeView(content: fullAddress)
                    .overlay {
                        // Center sakura logo
                        SakuraLogo()
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 52, height: 52)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                Spacer()

                // Network Selector
                HStack(spacing: 0) {
                    NetworkTab("Solana", isSelected: selectedNetwork == "Solana") {
                        selectedNetwork = "Solana"
                    }
                    NetworkTab("EVM", isSelected: selectedNetwork == "EVM") {
                        selectedNetwork = "EVM"
                    }
                }
                .padding(4)
                .background(Color(white: 0.93))
                .clipShape(Capsule())
                .padding(.bottom, 28)

                // Copy Address Button
                Button {
                    UIPasteboard.general.string = fullAddress
                    showToast.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 15))
                        Text("Copy Address")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.22, blue: 0.52),
                                Color(red: 0.85, green: 0.18, blue: 0.48)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 32,
                    topTrailingRadius: 32,
                    style: .continuous
                )
            )
            .padding(.top, 200)
            .ignoresSafeArea(edges: .bottom)
        }
        .dynamicIslandToast(isPresented: $showToast, value: .svmAddressCopied)
    }
}

// MARK: - Network Tab Button
struct NetworkTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(isSelected ? .white : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? .black.opacity(0.06) : .clear, radius: 4, y: 2)
        }
    }
}

// MARK: - Solana Icon (Three horizontal bars)
struct SolanaIcon: View {
    var body: some View {
        VStack(spacing: 3.5) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(.black)
                    .frame(height: 2.5)
            }
        }
    }
}

// MARK: - Green Network Icon
struct NetworkIcon: View {
    var body: some View {
        Circle()
            .fill(Color(red: 0.2, green: 0.55, blue: 0.2))
            .overlay {
                // Simplified floral/geometric pattern
                ZStack {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.3, green: 0.75, blue: 0.3))
                            .frame(width: 8, height: 8)
                            .offset(y: -6)
                            .rotationEffect(.degrees(Double(i) * 60))
                    }
                    Circle()
                        .fill(Color(red: 0.3, green: 0.75, blue: 0.3))
                        .frame(width: 7, height: 7)
                }
            }
    }
}

// MARK: - Sakura Logo (Center of QR)
struct SakuraLogo: View {
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Ellipse()
                    .fill(Color(red: 0.92, green: 0.30, blue: 0.55))
                    .frame(width: 14, height: 18)
                    .offset(y: -8)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
            Circle()
                .fill(Color(red: 0.85, green: 0.25, blue: 0.45))
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Dot-Style QR Code
struct DotQRCodeView: View {
    let content: String

    var body: some View {
        Canvas { ctx, size in
            guard let matrix = generateQRMatrix() else { return }
            let count = matrix.count
            let cellSize = size.width / CGFloat(count)
            let dotRadius = cellSize * 0.40

            // Draw finder patterns (rounded rectangles)
            drawFinderPattern(ctx: &ctx, cellSize: cellSize, col: 0, row: 0)
            drawFinderPattern(ctx: &ctx, cellSize: cellSize, col: count - 7, row: 0)
            drawFinderPattern(ctx: &ctx, cellSize: cellSize, col: 0, row: count - 7)

            // Draw all other modules as dots
            for row in 0..<count {
                for col in 0..<count {
                    guard matrix[row][col] else { continue }
                    guard !isInFinderPatternArea(row: row, col: col, size: count) else { continue }

                    let x = CGFloat(col) * cellSize + cellSize / 2
                    let y = CGFloat(row) * cellSize + cellSize / 2

                    let circle = Path(ellipseIn: CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    ))
                    ctx.fill(circle, with: .color(.black))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawFinderPattern(ctx: inout GraphicsContext, cellSize: CGFloat, col: Int, row: Int) {
        let x = CGFloat(col) * cellSize
        let y = CGFloat(row) * cellSize
        let cornerRadius = cellSize * 1.4

        // Outer (7x7) black rounded rect
        let outerRect = CGRect(x: x, y: y, width: cellSize * 7, height: cellSize * 7)
        let outerPath = Path(roundedRect: outerRect, cornerRadius: cornerRadius)
        ctx.fill(outerPath, with: .color(.black))

        // Inner gap (5x5) white rounded rect
        let gapRect = CGRect(
            x: x + cellSize,
            y: y + cellSize,
            width: cellSize * 5,
            height: cellSize * 5
        )
        let gapPath = Path(roundedRect: gapRect, cornerRadius: cornerRadius * 0.6)
        ctx.fill(gapPath, with: .color(.white))

        // Center core (3x3) black rounded rect
        let coreRect = CGRect(
            x: x + cellSize * 2,
            y: y + cellSize * 2,
            width: cellSize * 3,
            height: cellSize * 3
        )
        let corePath = Path(roundedRect: coreRect, cornerRadius: cornerRadius * 0.35)
        ctx.fill(corePath, with: .color(.black))
    }

    private func isInFinderPatternArea(row: Int, col: Int, size: Int) -> Bool {
        let finderSize = 7
        // Top-left
        if row < finderSize && col < finderSize { return true }
        // Top-right
        if row < finderSize && col >= size - finderSize { return true }
        // Bottom-left
        if row >= size - finderSize && col < finderSize { return true }
        return false
    }

    private func generateQRMatrix() -> [[Bool]]? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = "H"

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return nil }

        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8

        var matrix: [[Bool]] = []
        for y in 0..<height {
            var row: [Bool] = []
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let gray = ptr[offset]
                row.append(gray == 0)
            }
            matrix.append(row)
        }

        return matrix
    }
}

#Preview {
    ContentView()
}
