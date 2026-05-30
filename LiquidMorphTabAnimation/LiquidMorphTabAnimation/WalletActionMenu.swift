//
//  WalletActionMenu.swift
//  LiquidMorphTabAnimation
//
//  Staggered Deposit·Withdraw·Swap menu that expands from the FAB.
//  Mirrors suzi-swift's PortfolioFloatingDock.expandedActionMenu (lines 691-750).
//

import SwiftUI

// MARK: - Action model

enum FloatingWalletAction: String, CaseIterable, Identifiable {
    case deposit, withdraw, swap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deposit:  "Deposit"
        case .withdraw: "Withdraw"
        case .swap:     "Swap"
        }
    }

    /// SF Symbol placeholders chosen to roughly match suzi-swift's custom DepositIcon/WithdrawIcon/SwapIcon.
    var systemImage: String {
        switch self {
        case .deposit:  "arrow.up.right"
        case .withdraw: "paperplane.fill"
        case .swap:     "arrow.left.arrow.right"
        }
    }

    var tint: Color {
        switch self {
        case .deposit:  Colors.walletGreen
        case .withdraw: Color.accentRed
        case .swap:     Colors.walletBluePurple
        }
    }
}

// MARK: - View

struct WalletActionMenu: View {
    @Binding var isExpanded: Bool
    var onSelect: (FloatingWalletAction) -> Void

    private enum M {
        static let actionDiameter: CGFloat   = 56
        static let actionLabelSize: CGFloat  = 20
        static let actionIconSize: CGFloat   = 24
        static let expandDuration: Double    = 0.25
        static let collapseDuration: Double  = 0.18
        static let stagger: Double           = 0.035
        static let stackedStep: CGFloat      = 14
        static var expandedStep: CGFloat     { actionDiameter + Spacing.md }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 32) {
            ForEach(Array(FloatingWalletAction.allCases.enumerated()), id: \.element.id) { index, action in
                row(action, index: index)
            }
        }
    }

    private func row(_ action: FloatingWalletAction, index: Int) -> some View {
        Button {
            Haptics.medium()
            onSelect(action)
        } label: {
            HStack(spacing: 32) {
                Text(action.title)
                    .font(.system(size: M.actionLabelSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary.opacity(0.9))
                    .minimumScaleFactor(0.7)

                Image(systemName: action.systemImage)
                    .font(.system(size: M.actionIconSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: M.actionDiameter, height: M.actionDiameter)
                    .background(action.tint)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(scale(for: index), anchor: .trailing)
        .offset(y: offset(for: index))
        .zIndex(Double(FloatingWalletAction.allCases.count - index))
        .allowsHitTesting(isExpanded)
        .animation(animation(for: index), value: isExpanded)
    }

    // MARK: - Layout maths (matches suzi-swift)

    private func offset(for index: Int) -> CGFloat {
        guard !isExpanded else { return 0 }
        let reverseIndex = max(0, FloatingWalletAction.allCases.count - 1 - index)
        return CGFloat(reverseIndex) * (M.expandedStep - M.stackedStep)
    }

    private func scale(for index: Int) -> CGFloat {
        guard !isExpanded else { return 1 }
        let reverseIndex = max(0, FloatingWalletAction.allCases.count - 1 - index)
        return max(0.88, 1 - (CGFloat(reverseIndex) * 0.03))
    }

    private func animation(for index: Int) -> Animation {
        if isExpanded {
            return .snappy(duration: M.expandDuration, extraBounce: 0.06)
                .delay(Double(index) * M.stagger)
        }
        let reverseIndex = max(0, FloatingWalletAction.allCases.count - 1 - index)
        return .snappy(duration: M.collapseDuration, extraBounce: 0)
            .delay(Double(reverseIndex) * (M.stagger * 0.5))
    }
}

#Preview {
    @Previewable @State var open = true
    return ZStack {
        Color.appBackground.ignoresSafeArea()
        WalletActionMenu(isExpanded: $open) { _ in open = false }
            .padding(.trailing, 25)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
