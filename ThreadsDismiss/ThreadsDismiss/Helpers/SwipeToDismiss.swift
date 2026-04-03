//
//  SwipeToDismiss.swift
//  ThreadsDismiss
//
//  Created by Abhijit Sahoo on 01/04/26.
//

import SwiftUI

/// Only Making it available to ScrollView
extension ScrollView {
    @ViewBuilder
    func swipeUpToDismiss(_ threshold: CGFloat, bottomInset: CGFloat = 0, onDismiss: @escaping () -> ()) -> some View {
        self
            .modifier(SwipeToDismiss(threshold: threshold, bottomInset: bottomInset, onDismiss: onDismiss))
    }
}

struct SwipeToDismiss: ViewModifier {
    var threshold: CGFloat
    var bottomInset: CGFloat
    var onDismiss: () -> ()
    /// View Properties
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false
    @State private var isElligible: Bool = false
    @State private var isDismissTriggered: Bool = false
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .contentShape(.rect)
            /// From iOS 18+ Simultaneous Gesture Starts working with ScrollView!
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging, body: { _, out, _ in
                        out = true
                    })
            )
            .overlay(alignment: .bottom) {
                /// Bottom Drag Indicator
                let bottomOffset: CGFloat = scrollOffset < 0 ? -scrollOffset : 0
                /// For Offset Movement
                let movement: CGFloat = 50
                let movementProgress: CGFloat = max(min(bottomOffset / movement, 1), 0)
                let progress: CGFloat = (bottomOffset - movement) / (threshold - movement)
                let cappedProgress: CGFloat = isElligible ? (isDismissTriggered ? 1 : max(min(progress, 1), 0)) : 0
                let isFull: Bool = cappedProgress == 1

                ZStack {
                    Circle()
                        .fill(Color.pink)
                        .opacity(isFull ? 1 : 0)

                    /// Double Side Trim Circle Effect
                    ZStack {
                        Circle()
                            .trim(from: 0, to: cappedProgress / 2)
                            .stroke(lineWidth: 3)
                            .rotation(.init(degrees: 90))

                        Circle()
                            .trim(from: 0, to: cappedProgress / 2)
                            .stroke(lineWidth: 3)
                            .rotation(.init(degrees: 90))
                            .scale(x: -1)
                    }
                    .foregroundStyle(Color.pink)
                    .padding(3)

                    /// Arrow With Rotation Effect
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(isFull ? Color.white : Color.pink)
                        .rotationEffect(.init(degrees: cappedProgress * 90))
                }
                .frame(width: 55, height: 55)
                /// A Little Bounce effec when it reached full by using KeyFrame API
                .keyframeAnimator(initialValue: 1.0, trigger: isFull, content: { content, scale in
                    content
                        .scaleEffect(scale)
                }, keyframes: { _ in
                    CubicKeyframe(1.1, duration: 0.15)
                    CubicKeyframe(1, duration: 0.15)
                })
                .allowsHitTesting(false)
                .offset(y: movement - (movement * movementProgress) - bottomInset)
                .opacity(movementProgress)
                /// Haptic Feedback when it reached Full
                .sensoryFeedback(.selection, trigger: isFull) { oldValue, newValue in
                    return newValue
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                let offset = $0.contentOffset.y + $0.contentInsets.top
                let contentHeight = $0.contentSize.height
                let containerHeight = $0.containerSize.height
                /// Calculating offset from bottom (EG: Bottom will be zero!)
                return max(contentHeight - containerHeight, 0) - offset
            } action: { oldValue, newValue in
                scrollOffset = newValue
                checkAndDismiss(newValue)
            }
            .onChange(of: isDragging) { oldValue, newValue in
                if newValue {
                    isElligible = scrollOffset < (threshold * 1.2)
                }

                checkAndDismiss(scrollOffset)
            }
    }

    func checkAndDismiss(_ offset: CGFloat) {
        if !isDragging && isElligible && -scrollOffset >= threshold && !isDismissTriggered {
            onDismiss()
            isDismissTriggered = true
        }

        /// Resetting State after it reaches bottom!
        /// For Safer Side using value -10 instead of 0!
        if isDismissTriggered && !(offset.rounded() <= -10) && !isDragging {
            isDismissTriggered = false
        }
    }
}

#Preview {
    ContentView()
}
