//
//  MessageBubbleView.swift
//  xSidebarAnimation
//

import SwiftUI

struct MessageBubbleView: View {
    let message: DummyMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer(minLength: 60)
                userBubble
            } else {
                assistantBubble
                Spacer(minLength: 60)
            }
        }
    }

    private var userBubble: some View {
        Text(message.text)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.accentPink.opacity(0.18))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 16
                )
            )
    }

    private var assistantBubble: some View {
        Text(message.text)
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundColor(.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
