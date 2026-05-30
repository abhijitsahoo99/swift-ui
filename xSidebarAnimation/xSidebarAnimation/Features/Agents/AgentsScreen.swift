//
//  AgentsScreen.swift
//  xSidebarAnimation
//

import SwiftUI

struct AgentsScreen: View {
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    titleBlock

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(DummyAgents.all) { agent in
                            AgentCard(agent: agent)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 120) // dock clearance
                }
                .padding(.top, 4)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentPink, .walletBluePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)

                Text(DummyUser.handle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .tracking(-0.26)
                    .foregroundColor(.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Agents")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text("Specialised AI helpers for your trading flow.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
}

private struct AgentCard: View {
    let agent: DummyAgent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: agent.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: agent.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Text(agent.tagline)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Button { } label: {
                Text("Try")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.accentPink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.accentPink.opacity(0.14))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.backgroundSecondary)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }
}
