//
//  NetWorthCard.swift
//  xSidebarAnimation
//
//  Pink radial gradient card with split-styled balance text — port of
//  Suzi's NetWorthCardGradientBackground + rawBalanceText.
//

import SwiftUI
import UIKit

struct NetWorthCard: View {
    let value: String   // pre-formatted e.g. "$67.97"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Worth")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .tracking(-0.26)
                .foregroundColor(.white)

            balanceText
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background {
            NetWorthCardGradientBackground(cornerRadius: 34)
        }
    }

    private var balanceText: Text {
        if let dotIndex = value.range(of: ".")?.lowerBound {
            let integerPart = String(value[value.startIndex..<dotIndex])
            let decimalPart = String(value[dotIndex...])
            return Text(integerPart)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .tracking(-1.2)
            + Text(decimalPart)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .tracking(-0.6)
        }
        return Text(value)
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .tracking(-1.2)
    }
}

// MARK: - Pink radial gradient background (ported from TopPaneSummaryView.swift:804-874)

private enum NetWorthCardGradientSpec {
    static let designWidth: CGFloat = 362
    static let designHeight: CGFloat = 112
    static let gradientRadius: CGFloat = 10
    static let gradientTransform = CGAffineTransform(
        a: -5.2957,
        b: 11.036,
        c: -33.773,
        d: -9.9442,
        tx: 162.96,
        ty: 60.985
    )
    static let stops: [(CGFloat, UIColor)] = [
        (0.25481, UIColor(red: 1.0, green: 77.0 / 255.0, blue: 169.0 / 255.0, alpha: 1.0)),
        (0.51866, UIColor(red: 1.0, green: 39.0 / 255.0, blue: 140.0 / 255.0, alpha: 1.0)),
        (0.65059, UIColor(red: 1.0, green: 19.0 / 255.0, blue: 126.0 / 255.0, alpha: 1.0)),
        (0.71656, UIColor(red: 1.0, green: 10.0 / 255.0, blue: 118.0 / 255.0, alpha: 1.0)),
        (0.78252, UIColor(red: 1.0, green: 0.0, blue: 111.0 / 255.0, alpha: 1.0)),
        (0.80970, UIColor(red: 1.0, green: 19.0 / 255.0, blue: 124.0 / 255.0, alpha: 1.0)),
        (0.83689, UIColor(red: 1.0, green: 38.0 / 255.0, blue: 137.0 / 255.0, alpha: 1.0)),
        (0.89126, UIColor(red: 1.0, green: 77.0 / 255.0, blue: 163.0 / 255.0, alpha: 1.0)),
        (0.94563, UIColor(red: 1.0, green: 115.0 / 255.0, blue: 188.0 / 255.0, alpha: 1.0)),
        (1.0,     UIColor(red: 1.0, green: 153.0 / 255.0, blue: 214.0 / 255.0, alpha: 1.0)),
    ]
}

struct NetWorthCardGradientBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            let rect = CGRect(origin: .zero, size: size)

            context.withCGContext { cgContext in
                cgContext.saveGState()
                cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath)
                cgContext.clip()
                let colors = NetWorthCardGradientSpec.stops.map { $0.1.cgColor } as CFArray
                let locations = NetWorthCardGradientSpec.stops.map { $0.0 }
                guard let gradient = CGGradient(
                    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                    colors: colors,
                    locations: locations
                ) else {
                    cgContext.restoreGState()
                    return
                }

                let scaleTransform = CGAffineTransform(
                    scaleX: rect.width / NetWorthCardGradientSpec.designWidth,
                    y: rect.height / NetWorthCardGradientSpec.designHeight
                )

                cgContext.concatenate(scaleTransform)
                cgContext.concatenate(NetWorthCardGradientSpec.gradientTransform)
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: .zero,
                    startRadius: 0,
                    endCenter: .zero,
                    endRadius: NetWorthCardGradientSpec.gradientRadius,
                    options: [.drawsAfterEndLocation]
                )
                cgContext.restoreGState()
            }
        }
    }
}
