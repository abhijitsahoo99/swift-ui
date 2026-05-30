//
//  ChatScreen.swift
//  xSidebarAnimation
//

import SwiftUI

struct ChatScreen: View {
    var onToggleDrawer: () -> Void

    @State private var messages: [DummyMessage] = DummyMessages.sample
    @State private var draft: String = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 4)

                messageList

                ChatComposer(draft: $draft, onSend: sendMessage)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 96) // clearance for floating dock
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            glassCapsuleButton(systemName: "line.3.horizontal", action: onToggleDrawer)

            Spacer()

            Text("Chat")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            Spacer()

            glassCapsuleButton(systemName: "square.and.pencil", action: { newChat() })
        }
    }

    private func glassCapsuleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                glassCapsuleBackground
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var glassCapsuleBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
                .overlay {
                    Capsule().fill(Color.black.opacity(0.2)).blendMode(.screen)
                }
        } else {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(Color.white.opacity(0.04))
                Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(.init(role: .user, text: trimmed))
        draft = ""

        // Fake assistant reply
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            messages.append(.init(role: .assistant, text: "Got it — let me look into that."))
        }
    }

    private func newChat() {
        messages = []
    }
}
