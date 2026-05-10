//
//  TiltableCard.swift
//  metalShader
//
//  Wraps a card view with drag-based 3D tilt, dynamic shadow that tracks the
//  tilt direction, and exposes tilt angles (in degrees) to its content so a
//  Metal shader / parallax layer inside can react to them.
//

import SwiftUI

struct TiltableCard<Content: View>: View {
    /// Maximum tilt in degrees along either axis.
    var maxTilt: Double = 12
    /// Corner radius used when hit-testing the tilt gesture.
    var cornerRadius: CGFloat = 20
    /// Content closure — receives (tiltX, tiltY) in degrees.
    ///  • tiltX: rotation around the X-axis (pitch, positive = top tilts back).
    ///  • tiltY: rotation around the Y-axis (yaw, positive = right side tilts back).
    let content: (Double, Double) -> Content

    init(
        maxTilt: Double = 12,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: @escaping (Double, Double) -> Content
    ) {
        self.maxTilt = maxTilt
        self.cornerRadius = cornerRadius
        self.content = content
    }

    @State private var dragTiltX: Double = 0
    @State private var dragTiltY: Double = 0
    @State private var isDragging: Bool = false

    // Ambient sway amplitude — small continuous oscillation when the card is
    // idle, so it feels alive (like Apple Wallet cards).
    private let ambientAmplitude: Double = 2.5

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // Gentle breathing when not being dragged; zero while dragging so
            // the user's input is the only contribution.
            let amp = isDragging ? 0.0 : ambientAmplitude
            let ambientX = sin(t * 0.45) * amp
            let ambientY = cos(t * 0.60) * amp * 1.2

            let finalX = dragTiltX + ambientX
            let finalY = dragTiltY + ambientY

            GeometryReader { geo in
                content(finalX, finalY)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .rotation3DEffect(
                        .degrees(finalX),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.6
                    )
                    .rotation3DEffect(
                        .degrees(finalY),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.6
                    )
                    .shadow(
                        color: .black.opacity(0.35 + min(0.25, (abs(finalX) + abs(finalY)) / 40.0)),
                        radius: 18 + (abs(finalX) + abs(finalY)) * 0.6,
                        x: -finalY * 1.8,
                        y: 8 + finalX * 1.8
                    )
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { value in
                                let w = geo.size.width
                                let h = geo.size.height
                                guard w > 0, h > 0 else { return }
                                let nx = min(max(Double(value.location.x / w * 2 - 1), -1), 1)
                                let ny = min(max(Double(value.location.y / h * 2 - 1), -1), 1)
                                if !isDragging {
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        dragTiltY = nx * maxTilt
                                        dragTiltX = -ny * maxTilt
                                    }
                                    isDragging = true
                                } else {
                                    dragTiltY = nx * maxTilt
                                    dragTiltX = -ny * maxTilt
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                                    dragTiltX = 0
                                    dragTiltY = 0
                                }
                            }
                    )
            }
        }
    }
}

#Preview {
    TiltableCard { tX, tY in
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(LinearGradient(
                colors: [.pink.opacity(0.8), .purple.opacity(0.8)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
                Text(String(format: "tiltX %.1f° / tiltY %.1f°", tX, tY))
                    .foregroundStyle(.white)
                    .font(.caption)
            )
    }
    .frame(width: 300, height: 180)
    .padding(40)
    .background(Color.black)
}
