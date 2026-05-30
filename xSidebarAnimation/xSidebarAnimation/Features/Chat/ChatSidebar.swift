//
//  ChatSidebar.swift
//  xSidebarAnimation
//
//  Visual recreation of Suzi's ChatConversationsSidePanel — header,
//  Pinned + Recents sections, conversation rows, glass-pill Search +
//  circular "+" floating bar.
//

import SwiftUI

struct ChatSidebar: View {
    @Binding var isExpanded: Bool
    @Binding var selectedConversationId: UUID?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                header
                chatsList
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black, location: 0.04),
                                .init(color: .black, location: 0.92),
                                .init(color: .clear, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            floatingBar
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.accentPink)
                .frame(width: 34, height: 34)

            Text("Suzi")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Chats list

    private var chatsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                section(title: "Pinned", icon: "pin.fill", conversations: DummyConversations.pinned)
                section(title: "Recents", icon: nil, conversations: DummyConversations.recents)
            }
            .padding(.top, 24)
            .padding(.bottom, 120) // clearance for floating bar
        }
    }

    private func section(title: String, icon: String?, conversations: [DummyConversation]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: title, icon: icon)
            LazyVStack(spacing: 4) {
                ForEach(conversations) { conversation in
                    conversationRow(conversation)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func sectionHeader(title: String, icon: String?) -> some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.mutedLabel)
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.mutedLabel)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    private func conversationRow(_ conversation: DummyConversation) -> some View {
        let isActive = selectedConversationId == conversation.id
        return Button {
            selectedConversationId = conversation.id
            isExpanded = false
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .tracking(-0.26)
                    .foregroundColor(Color(red: 0.91, green: 0.91, blue: 0.91))
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    Text(conversation.lastUpdated)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .tracking(-0.23)
                        .foregroundColor(Color(red: 0.39, green: 0.39, blue: 0.40))

                    if conversation.hasUnreadReply {
                        Circle()
                            .fill(Color.accentPink)
                            .frame(width: 6, height: 6)
                        Text("New")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .tracking(-0.23)
                            .foregroundColor(.accentPink)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.06) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floating bar

    private var floatingBar: some View {
        HStack(spacing: 14) {
            searchPill
            Spacer(minLength: 0)
            newChatCircle
        }
    }

    private var searchPill: some View {
        Button {
            // No-op for demo
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .frame(width: 28, height: 28)
                    .padding(.leading, 6)
                Text("Search")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .padding(.trailing, 10)
            }
            .frame(width: 124, height: 52)
            .background(glassCapsuleBackground)
            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glassCapsuleBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(Color.accentPink.opacity(0.2)), in: .capsule)
                .overlay {
                    Capsule().fill(Color.black.opacity(0.2)).blendMode(.screen)
                }
        } else {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color.accentPink.opacity(0.18))
                Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }

    private var newChatCircle: some View {
        Button {
            // No-op for demo
        } label: {
            ZStack {
                glassCircleBackground
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.accentPinkLight)
            }
            .frame(width: 52, height: 52)
            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glassCircleBackground: some View {
        if #available(iOS 26.0, *) {
            Circle()
                .fill(.clear)
                .glassEffect(.regular.tint(Color.accentPink.opacity(0.2)).interactive(), in: .circle)
                .overlay {
                    Circle().fill(Color.black.opacity(0.2)).blendMode(.screen)
                }
        } else {
            ZStack {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(Color.accentPink.opacity(0.18))
                Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }
}
