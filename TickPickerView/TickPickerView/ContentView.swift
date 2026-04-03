//
//  ContentView.swift
//  TickPickerView
//
//  Created by Abhijit Sahoo on 31/03/26.
//

import SwiftUI

struct ContentView: View {
    @State private var netWorth: Double = 1456.23
    @State private var baseNetWorth: Double = 1456.23
    @State private var percentChange: Double = 3.4
    @State private var selectedPeriod: String = "1M"
    @State private var positionsValue: Double = 216.81
    @State private var ordersValue: Double = 139.00
    @State private var holdingsValue: Double = 1152.00

    // Tick picker drives the chart scrub
    @State private var tickSelection: Int = 100
    private let tickCount: Int = 100

    // Tracks whether user is actively dragging (scrubbing) vs tapping
    @State private var isScrubbing: Bool = false

    let periods = ["7D", "1M", "3M"]

    // Chart data points (simulated net worth over time)
    let chartDataPoints: [Double] = [
        1320, 1335, 1358, 1342, 1370, 1395, 1380, 1410,
        1390, 1425, 1405, 1440, 1420, 1460, 1435, 1470,
        1445, 1456.23
    ]

    // Normalized scrub position (0.0 to 1.0) from tick picker
    private var scrubFraction: CGFloat {
        CGFloat(tickSelection) / CGFloat(tickCount)
    }

    // Interpolated value from chart data at current scrub position
    private var scrubValue: Double {
        let count = chartDataPoints.count
        guard count > 1 else { return chartDataPoints.first ?? 0 }
        let floatIndex = scrubFraction * CGFloat(count - 1)
        let lower = max(0, min(Int(floatIndex), count - 2))
        let upper = lower + 1
        let frac = Double(floatIndex) - Double(lower)
        return chartDataPoints[lower] + (chartDataPoints[upper] - chartDataPoints[lower]) * frac
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.top, 8)

                    netWorthSection
                        .padding(.top, 24)

                    // Green line chart (driven by tick picker + tappable)
                    LineChartView(
                        dataPoints: chartDataPoints,
                        scrubFraction: scrubFraction,
                        onTap: { fraction in
                            // Single tap — use rolling animation
                            let newTick = max(0, min(Int(fraction * CGFloat(tickCount)), tickCount))
                            tickSelection = newTick
                        },
                        onDragChanged: { fraction in
                            // Dragging — direct update, no rolling
                            isScrubbing = true
                            let newTick = max(0, min(Int(fraction * CGFloat(tickCount)), tickCount))
                            tickSelection = newTick
                        },
                        onDragEnded: {
                            isScrubbing = false
                        }
                    )
                    .frame(height: 200)
                    .padding(.top, 20)

                    // Tick picker with glass scrub thumb
                    tickScrubber
                        .padding(.top, 8)

                    periodSelector
                        .padding(.top, 16)

                    cardsSection
                        .padding(.top, 24)

                    holdingsSection
                        .padding(.top, 24)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }

            bottomTabBar
        }
        .background(Color(.systemBackground))
        .fontDesign(.rounded)
        .onChange(of: tickSelection) { _, newValue in
            netWorth = scrubValue
            let baseVal = chartDataPoints.first ?? 1320
            percentChange = ((scrubValue - baseVal) / baseVal) * 100.0
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.38, green: 0.25, blue: 0.85), Color(red: 0.50, green: 0.35, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                )

            HStack(spacing: 4) {
                Text("Main Wallet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Circle()
                .fill(Color(.systemGray6))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "clock")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                )

            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(.systemGray))
                )
        }
    }

    // MARK: - Net Worth Section
    private var netWorthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Worth")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(.systemGray))

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                AnimatedNumberView(value: netWorth, useRolling: !isScrubbing)

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8, weight: .bold))
                        .rotationEffect(percentChange >= 0 ? .zero : .degrees(180))
                    Text(String(format: "%.1f%%", abs(percentChange)))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(percentChange >= 0
                    ? Color(red: 0.20, green: 0.65, blue: 0.35)
                    : Color(red: 0.90, green: 0.30, blue: 0.30))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill((percentChange >= 0
                            ? Color(red: 0.20, green: 0.65, blue: 0.35)
                            : Color(red: 0.90, green: 0.30, blue: 0.30)).opacity(0.12))
                )
            }
        }
    }

    // MARK: - Tick Scrubber with Glass Thumb
    private var tickScrubber: some View {
        ZStack {
            TickPicker(
                count: tickCount,
                config: .init(
                    tickWidth: 2,
                    tickHeight: 30,
                    tickHPadding: 3,
                    activeTint: Color(red: 0.20, green: 0.65, blue: 0.35),
                    inActiveTint: .primary.opacity(0.3),
                    alignment: .center
                ),
                selection: $tickSelection,
                onScrollPhaseChanged: { phase in
                    isScrubbing = phase != .idle
                }
            )

            // Liquid glass scrub thumb — sits at the center (where active tick is)
            Capsule()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 8, y: 2)
                .allowsHitTesting(false)
        }
        .frame(height: 50)
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 24) {
            Spacer()
            ForEach(periods, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                    simulateValueChange(for: period)
                } label: {
                    Text(period)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(selectedPeriod == period ? .primary : Color(.systemGray2))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(selectedPeriod == period ? Color(.systemGray3) : .clear, lineWidth: 1)
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - Cards Section
    private var cardsSection: some View {
        HStack(spacing: 12) {
            cardView(
                title: "Positions",
                icons: ["dollarsign.circle.fill", "flame.fill"],
                iconColors: [Color(red: 0.30, green: 0.50, blue: 0.90), Color(red: 0.95, green: 0.55, blue: 0.20)],
                value: positionsValue
            )
            cardView(
                title: "Orders",
                icons: ["arrow.triangle.2.circlepath"],
                iconColors: [Color(red: 0.20, green: 0.75, blue: 0.70)],
                value: ordersValue
            )
        }
    }

    private func cardView(title: String, icons: [String], iconColors: [Color], value: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.systemGray2))
            }

            HStack(spacing: -6) {
                ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                    Circle()
                        .fill(iconColors[index])
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        )
                }
            }
            .padding(.top, 16)

            Text(formatCurrency(value))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.8))
        )
    }

    // MARK: - Holdings Section
    private var holdingsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Holdings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(formatCurrency(holdingsValue))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 16)

            Divider()

            holdingRow(name: "Solana", symbol: "SOL", icon: "circle.fill", color: .purple, amount: "$822.22", subtext: "7.2 SOL")
            holdingRow(name: "USDC.e", symbol: "USDC", icon: "dollarsign.circle.fill", color: .blue, amount: "$263.5", subtext: "263.5 USDC")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.8))
        )
    }

    private func holdingRow(name: String, symbol: String, icon: String, color: Color, amount: String, subtext: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtext)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(.systemGray))
            }

            Spacer()

            Text(amount)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Bottom Tab Bar
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 20, weight: .medium))
                Text("Trade")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Color(.systemGray))

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 20, weight: .medium))
                Text("Agents")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Color(.systemGray))

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: -2)
        )
        .padding(.horizontal, 80)
    }

    // MARK: - Helpers
    private func formatCurrency(_ value: Double) -> String {
        if value == value.rounded() && value >= 100 {
            return "$\(Int(value).formatted())"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func simulateValueChange(for period: String) {
        withAnimation(.easeInOut(duration: 0.6)) {
            switch period {
            case "7D":
                netWorth = 1389.50
                baseNetWorth = 1389.50
                percentChange = 1.2
                positionsValue = 198.45
                ordersValue = 122.00
                holdingsValue = 1069.05
            case "1M":
                netWorth = 1456.23
                baseNetWorth = 1456.23
                percentChange = 3.4
                positionsValue = 216.81
                ordersValue = 139.00
                holdingsValue = 1152.00
            case "3M":
                netWorth = 1234.87
                baseNetWorth = 1234.87
                percentChange = -2.1
                positionsValue = 180.22
                ordersValue = 105.50
                holdingsValue = 949.15
            default:
                break
            }
        }
    }
}

// MARK: - Line Chart (Controlled by tick picker + tappable/scrubbable)
struct LineChartView: View {
    let dataPoints: [Double]
    let scrubFraction: CGFloat // 0.0 to 1.0
    var onTap: ((CGFloat) -> Void)? = nil
    var onDragChanged: ((CGFloat) -> Void)? = nil
    var onDragEnded: (() -> Void)? = nil

    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minVal = (dataPoints.min() ?? 0) - 20
            let maxVal = (dataPoints.max() ?? 0) + 20
            let points = computePoints(width: w, height: h, minVal: minVal, maxVal: maxVal)
            let scrubX = scrubFraction * w
            let scrubVal = interpolatedValue(at: scrubX, width: w)
            let scrubY = yPosition(for: scrubVal, height: h, minVal: minVal, maxVal: maxVal)

            ZStack(alignment: .topLeading) {
                // Gradient fill
                closedPath(points: points, width: w, height: h)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.65, blue: 0.35).opacity(0.20),
                                Color(red: 0.20, green: 0.65, blue: 0.35).opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Line stroke
                linePath(points: points)
                    .stroke(Color(red: 0.20, green: 0.65, blue: 0.35), lineWidth: 2)

                // Scrub indicator (tooltip + line + dot)
                VStack(spacing: 0) {
                    Text("$\(Int(scrubVal))")
                        .font(.system(size: 13, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        )

                    Rectangle()
                        .fill(Color(.systemGray3))
                        .frame(width: 1, height: max(0, scrubY - 30))

                    Circle()
                        .fill(Color(red: 0.20, green: 0.65, blue: 0.35))
                        .frame(width: 8, height: 8)
                }
                .position(x: scrubX, y: (scrubY + 30) / 2)
                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.85), value: scrubFraction)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = max(0, min(value.location.x / w, 1.0))
                        if !isDragging {
                            // First touch — treat as tap
                            isDragging = true
                            onTap?(fraction)
                        } else {
                            // Continued drag — scrub mode
                            onDragChanged?(fraction)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        onDragEnded?()
                    }
            )
        }
    }

    private func closedPath(points: [CGPoint], width: CGFloat, height: CGFloat) -> Path {
        Path { path in
            guard !points.isEmpty else { return }
            path.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
            }
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        Path { path in
            guard !points.isEmpty else { return }
            path.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let midX = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
            }
        }
    }

    private func computePoints(width: CGFloat, height: CGFloat, minVal: Double, maxVal: Double) -> [CGPoint] {
        guard dataPoints.count > 1 else { return [] }
        let step = width / CGFloat(dataPoints.count - 1)
        return dataPoints.enumerated().map { index, value in
            let x = CGFloat(index) * step
            let y = height - CGFloat((value - minVal) / (maxVal - minVal)) * height * 0.85 - height * 0.05
            return CGPoint(x: x, y: y)
        }
    }

    private func interpolatedValue(at x: CGFloat, width: CGFloat) -> Double {
        guard dataPoints.count > 1, width > 0 else { return dataPoints.first ?? 0 }
        let step = width / CGFloat(dataPoints.count - 1)
        let floatIndex = x / step
        let lower = max(0, min(Int(floatIndex), dataPoints.count - 2))
        let upper = lower + 1
        let frac = Double(floatIndex) - Double(lower)
        return dataPoints[lower] + (dataPoints[upper] - dataPoints[lower]) * frac
    }

    private func yPosition(for value: Double, height: CGFloat, minVal: Double, maxVal: Double) -> CGFloat {
        height - CGFloat((value - minVal) / (maxVal - minVal)) * height * 0.85 - height * 0.05
    }
}

// MARK: - Animated Number View
// Supports two modes:
// - useRolling = true  → digits roll/morph individually (for taps, discrete jumps)
// - useRolling = false → direct text update every frame (for continuous scrubbing)
struct AnimatedNumberView: View {
    let value: Double
    var useRolling: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.primary)

            if useRolling {
                Text(wholePart)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: value))
                    .animation(.easeInOut(duration: 0.5), value: value)

                Text(".\(decimalPart)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: value))
                    .animation(.easeInOut(duration: 0.5), value: value)
            } else {
                Text(wholePart)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.primary)

                Text(".\(decimalPart)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var wholePart: String {
        Int(value).formatted()
    }

    private var decimalPart: String {
        let decimal = Int((value.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d", abs(decimal))
    }
}

#Preview {
    ContentView()
}
