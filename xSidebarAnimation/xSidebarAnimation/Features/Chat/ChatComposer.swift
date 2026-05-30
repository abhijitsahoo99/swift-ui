//
//  ChatComposer.swift
//  xSidebarAnimation
//

import SwiftUI

struct ChatComposer: View {
    @Binding var draft: String
    var onSend: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Ask Suzi...", text: $draft, axis: .vertical)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .tint(.accentPink)
                    .autocorrectionDisabled()
                    .submitLabel(.send)
                    .lineLimit(1...4)
                    .padding(.leading, 18)
                    .padding(.vertical, 14)

                sendButton
                    .padding(.trailing, 6)
            }
            .background(Color.accentPink.opacity(0.10))
            .clipShape(Capsule())
        }
    }

    private var sendButton: some View {
        Button(action: onSend) {
            ZStack {
                Circle()
                    .fill(Color.accentPink)
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
    }
}
