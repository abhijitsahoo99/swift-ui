
//
//  CustomAlertDrawer.swift
//  AlertDrawer
//
//  Created by Balaji Venkatesh on 30/03/25.
//

import SwiftUI

/// Drawer Config
struct DrawerConfig {
    var tint: Color
    var foreground: Color
    var clipShape: AnyShape
    /// Limiting access to only this file (Only set)
    fileprivate(set) var isPresented: Bool = false
    fileprivate(set) var sourceRect: CGRect = .zero

    init(
        tint: Color = .red,
        foreground: Color = .white,
        clipShape: AnyShape = .init(.capsule)
    ) {
        self.tint = tint
        self.foreground = foreground
        self.clipShape = clipShape
    }
}

// MARK: - Animation Constants
private enum DrawerAnimation {
    /// Main drawer spring — under-damped for a natural, lively feel
    static let presentation = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 350,
        damping: 28,
        initialVelocity: 0
    )
    /// Dismiss — slightly faster, critically damped (no bounce on close)
    static let dismissal = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 400,
        damping: 35,
        initialVelocity: 0
    )
    /// Backdrop fade
    static let backdrop = Animation.easeOut(duration: 0.25)
}

// MARK: Drawer Source Button (Generic Label)
struct DrawerButton<Label: View>: View {
    @Binding var config: DrawerConfig
    @ViewBuilder var label: Label
    var body: some View {
        Button {
            withAnimation(DrawerAnimation.presentation) {
                config.isPresented = true
            }
        } label: {
            label
        }
        .buttonStyle(ScaledButtonStyle())
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: { newValue in
            config.sourceRect = newValue
        }
    }
}

// MARK: Custom Alert Drawer Overlay View
extension View {
    @ViewBuilder
    func alertDrawer<Content: View>(
        config: Binding<DrawerConfig>,
        primaryTitle: String,
        secondaryTitle: String,
        onPrimaryClick: @escaping () -> Bool,
        onSecondaryClick: @escaping () -> Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GeometryReader { geometry in
                    let isPresented = config.wrappedValue.isPresented

                    // MARK: Backdrop
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(isPresented ? 1 : 0)
                        .animation(DrawerAnimation.backdrop, value: isPresented)
                        .onTapGesture {
                            guard config.wrappedValue.isPresented else { return }
                            withAnimation(DrawerAnimation.dismissal) {
                                config.wrappedValue.isPresented = false
                            }
                        }
                        .allowsHitTesting(isPresented)

                    // MARK: Drawer Card
                    AlertDrawerContent(
                        proxy: geometry,
                        primaryTitle: primaryTitle,
                        secondaryTitle: secondaryTitle,
                        onPrimaryClick: onPrimaryClick,
                        onSecondaryClick: onSecondaryClick,
                        config: config,
                        content: content
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .ignoresSafeArea()
            }
    }
}

fileprivate struct AlertDrawerContent<Content: View>: View {
    var proxy: GeometryProxy
    var primaryTitle: String
    var secondaryTitle: String
    var onPrimaryClick: () -> Bool
    var onSecondaryClick: () -> Bool
    @Binding var config: DrawerConfig
    @ViewBuilder var content: Content

    var body: some View {
        let isPresented = config.isPresented
        let screenHeight = proxy.size.height
        let safeBottom = proxy.safeAreaInsets.bottom

        VStack(spacing: 15) {
            content
                /// Close Button
                .overlay(alignment: .topTrailing) {
                    Button(action: dismissDrawer) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.primary, .gray.opacity(0.35))
                    }
                }

            /// Actions
            HStack(spacing: 10) {
                Button {
                    if onSecondaryClick() {
                        dismissDrawer()
                    }
                } label: {
                    Text(secondaryTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(config.foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(config.tint.opacity(0.3), in: config.clipShape)
                }

                Button {
                    if onPrimaryClick() {
                        dismissDrawer()
                    }
                } label: {
                    Text(primaryTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(config.foreground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(config.tint, in: config.clipShape)
                }
            }
            .buttonStyle(ScaledButtonStyle())
            .padding(.top, 10)
        }
        .padding([.horizontal, .top], 20)
        .padding(.bottom, 15)
        .background(.background)
        .clipShape(.rect(cornerRadius: 24))
        .shadow(color: .black.opacity(isPresented ? 0.15 : 0), radius: 20, x: 0, y: -8)
        .padding(.horizontal, 16)
        .padding(.bottom, max(safeBottom, 10))
        // Position: anchored to bottom, slides off-screen when dismissed
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: isPresented ? 0 : screenHeight)
        .animation(isPresented ? DrawerAnimation.presentation : DrawerAnimation.dismissal, value: isPresented)
        .allowsHitTesting(config.isPresented)
    }

    private func dismissDrawer() {
        withAnimation(DrawerAnimation.dismissal) {
            config.isPresented = false
        }
    }
}

// MARK: Custom Button Style
fileprivate struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
