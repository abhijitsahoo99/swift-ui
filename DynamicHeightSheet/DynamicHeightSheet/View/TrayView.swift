//
//  TrayView.swift
//  DynamicHeightSheet
//
//  Created by Balaji Venkatesh on 31/08/25.
//

import SwiftUI

/// View 1 Mock Data
struct DepositOption: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var image: String
    var title: String
}

let depositOptions: [DepositOption] = [
    .init(image: "arrow.left.arrow.right", title: "Transfer within Accounts"),
    .init(image: "arrow.down.left.circle", title: "Transfer from external wallet"),
    .init(image: "creditcard.fill", title: "Buy from MoonPay"),
    .init(image: "qrcode", title: "Receive Funds"),
]

/// View 2 Mock Data
struct Account: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var tokens: [Token]
}

struct Token: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var symbol: String
    var imageName: String
}

let account1Tokens: [Token] = [
    .init(name: "Solana", symbol: "SOL", imageName: "sol"),
    .init(name: "USD Coin", symbol: "USDC", imageName: "usdc"),
    .init(name: "Ethereum", symbol: "ETH", imageName: "eth"),
]

let account2Tokens: [Token] = [
    .init(name: "Solana", symbol: "SOL", imageName: "sol"),
    .init(name: "USD Coin", symbol: "USDC", imageName: "usdc"),
    .init(name: "Ethereum", symbol: "ETH", imageName: "eth"),
    .init(name: "Solana", symbol: "SOL", imageName: "sol"),
    .init(name: "USD Coin", symbol: "USDC", imageName: "usdc"),
    .init(name: "Ethereum", symbol: "ETH", imageName: "eth"),
    .init(name: "Solana", symbol: "SOL", imageName: "sol"),
    .init(name: "USD Coin", symbol: "USDC", imageName: "usdc"),
]

let accounts: [Account] = [
    .init(title: "Account 1", tokens: account1Tokens),
    .init(title: "Account 2", tokens: account2Tokens),
]

/// View 3 Mock Data
struct KeyPad: Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var value: Int
    var isBack: Bool = false
}

enum CurrentView {
    case actions
    case transfer
    case keypad
}

/// Custom keypad data ranges from 0 to 9 and includes a back button
let keypadValues: [KeyPad] = (1...9).compactMap({ .init(title: String("\($0)"), value: $0) }) + [
    .init(title: "0", value: 0),
    .init(title: "chevron.left", value: -1, isBack: true)
]

struct TrayView: View {
    var animation: Animation
    @State private var currentView: CurrentView = .actions
    @State private var selectedOption: DepositOption?
    @State private var selectedAccount: Account? = accounts.first
    @State private var selectedToken: Token?
    @State private var amount: String = ""
    @State private var showAccountPicker: Bool = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                switch currentView {
                case .actions: View1()
                        .geometryGroup()
                        .transition(
                            .blurReplace(.upUp)
                        )
                case .transfer: View2()
                        .geometryGroup()
                        .transition(
                            .blurReplace(.downUp)
                        )
                case .keypad: View3()
                        .geometryGroup()
                        .transition(.blurReplace(.upUp))
                }
            }
            .geometryGroup()

            /// Continue Button
            Button {
                if currentView == .actions {
                    withAnimation(animation) {
                        currentView = .transfer
                    }
                } else if currentView == .transfer {
                    // Token selected, go to amount input
                    if selectedToken != nil {
                        withAnimation(animation) {
                            currentView = .keypad
                        }
                    }
                } else {
                    print("Deposit \(amount) \(selectedToken?.symbol ?? "")")
                }
            } label: {
                Text(currentView == .keypad ? "Confirm Deposit" : "Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(.blue, in: .capsule)
            }
            .disabledWithOpacity(currentView == .actions ? selectedOption == nil : false)
            .disabledWithOpacity(currentView == .transfer ? selectedToken == nil : false)
            .disabledWithOpacity(currentView == .keypad ? amount.isEmpty : false)
            .padding(.top, 15)
            .geometryGroup()
        }
        .padding([.horizontal, .top], 20)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    /// View 1 - Deposit Account
    @ViewBuilder
    func View1() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Deposit Account")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 10)

            /// Deposit Options
            ForEach(depositOptions) { option in
                let isSelected: Bool = selectedOption?.id == option.id

                HStack(spacing: 10) {
                    Image(systemName: option.image)
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.1), in: .circle)

                    Text(option.title)
                        .fontWeight(.semibold)
                        .font(.callout)

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                        .font(.title)
                        .contentTransition(.symbolEffect)
                        .foregroundStyle(isSelected ? Color.blue : Color.gray.opacity(0.2))
                }
                .padding(.vertical, 6)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.snappy) {
                        selectedOption = isSelected ? nil : option
                    }
                }
            }
        }
    }

    /// View 2 - Transfer within Account
    @ViewBuilder
    func View2() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Transfer within Account")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    withAnimation(animation) {
                        currentView = .actions
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 10)

            /// From Account Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("From")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                Menu {
                    ForEach(accounts) { account in
                        Button {
                            withAnimation(animation) {
                                selectedAccount = account
                                selectedToken = nil
                            }
                        } label: {
                            HStack {
                                Text(account.title)
                                if selectedAccount?.id == account.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedAccount?.title ?? "Account 1")
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    }
                }
            }

            /// Token Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Tokens")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                let currentTokens = selectedAccount?.tokens ?? account1Tokens
                let tokenListHeight: CGFloat = min(CGFloat(currentTokens.count) * 60, 300)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(currentTokens) { token in
                            let isSelected = selectedToken?.id == token.id

                            HStack(spacing: 12) {
                                /// Token Icon
                                Image(token.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(.circle)
                                    .background {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                    }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(token.name)
                                        .fontWeight(.semibold)

                                    Text(token.symbol)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                                    .font(.title2)
                                    .contentTransition(.symbolEffect)
                                    .foregroundStyle(isSelected ? Color.blue : Color.gray.opacity(0.2))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.clear)
                            }
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selectedToken = isSelected ? nil : token
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(height: tokenListHeight)
            }
        }
    }

    /// View 3 - Input Amount
    @ViewBuilder
    func View3() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Input Amount")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)

                Button {
                    withAnimation(animation) {
                        currentView = .transfer
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 10)

            VStack(spacing: 6) {
                Text(amount.isEmpty ? "0" : amount)
                    .font(.system(size: 60, weight: .black))
                    .contentTransition(.numericText())

                if let token = selectedToken {
                    Text(token.symbol)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.vertical, 20)

            /// Custom Keypad View
            LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 15) {
                ForEach(keypadValues) { keyValue in
                    if keyValue.value == 0 {
                        Spacer()
                    }

                    Group {
                        if keyValue.isBack {
                            Image(systemName: keyValue.title)
                        } else {
                            Text(keyValue.title)
                        }
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            if keyValue.isBack {
                                if !amount.isEmpty {
                                    amount.removeLast()
                                }
                            } else {
                                amount.append(keyValue.title)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, -15)
        }
    }
}

extension View {
    func disabledWithOpacity(_ status: Bool) -> some View {
        self
            .disabled(status)
            .opacity(status ? 0.5 : 1)
    }
}
