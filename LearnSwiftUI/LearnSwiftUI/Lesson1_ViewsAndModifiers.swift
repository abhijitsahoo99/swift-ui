import SwiftUI

// LESSON 1: Views & Modifiers
// ===========================
// Everything in SwiftUI is a View.
// You style views by chaining modifiers — like setting properties in Figma's right panel.
// Read each section top to bottom. Change values and see what happens.

struct Lesson1_ViewsAndModifiers: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {

                // SECTION 1: Basic Views
                // ----------------------
                // These are SwiftUI's primitives — like Figma's rectangle, text, ellipse.

                SectionHeader(title: "Basic Views", subtitle: "The building blocks")

                VStack(spacing: 20) {
                    // Text — just like a text layer in Figma
                    Text("Hello, Designer")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    // Rectangle — like a rectangle in Figma
                    Rectangle()
                        .fill(.blue)
                        .frame(width: 120, height: 80)

                    // RoundedRectangle — rectangle with corner radius
                    // In Figma you'd set corner radius in the right panel.
                    // Here, the radius is part of the shape itself.
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.purple)
                        .frame(width: 120, height: 80)

                    // Circle — like an ellipse with equal W and H
                    Circle()
                        .fill(.orange)
                        .frame(width: 60, height: 60)

                    // Capsule — like a pill shape (rectangle with full radius)
                    Capsule()
                        .fill(.pink)
                        .frame(width: 140, height: 48)
                }

                Divider().background(.gray)

                // SECTION 2: Modifiers = Figma's Right Panel
                // ------------------------------------------
                // Modifiers are how you style views.
                // .frame() = width/height
                // .foregroundStyle() = text/icon color
                // .background() = fill
                // .padding() = padding (auto layout)
                // .clipShape() = corner radius mask
                // .shadow() = drop shadow
                // .opacity() = opacity

                SectionHeader(title: "Modifiers", subtitle: "Like Figma's right panel properties")

                // A styled card — read each modifier like a Figma property
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notification")
                        .font(.caption)            // Typography: Caption
                        .foregroundStyle(.gray)     // Color: Gray

                    Text("Your order is on the way")
                        .font(.body.weight(.semibold))   // Typography: Body Semibold
                        .foregroundStyle(.white)          // Color: White
                }
                .frame(maxWidth: .infinity, alignment: .leading)  // Fill width, left-aligned
                .padding(20)                                       // Padding: 20 all sides
                .background(.white.opacity(0.08))                  // Fill: white at 8%
                .clipShape(RoundedRectangle(cornerRadius: 16))     // Corner radius: 16
                .padding(.horizontal, 20)                          // Outer horizontal margin

                Divider().background(.gray)

                // SECTION 3: Stacks = Figma's Auto Layout
                // ----------------------------------------
                // VStack = vertical auto layout (↓)
                // HStack = horizontal auto layout (→)
                // ZStack = layers stacked on top of each other (like Figma layers)

                SectionHeader(title: "Stacks", subtitle: "Figma's Auto Layout")

                // HStack — items arranged horizontally
                // Like a horizontal auto layout frame in Figma
                HStack(spacing: 12) {   // spacing = item spacing in auto layout
                    Circle()
                        .fill(.green)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Abhijit")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                        Text("Online")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Spacer()    // Pushes everything to the left (like "space between" in Figma)

                    Image(systemName: "phone.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                .padding(16)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                // ZStack — layers on top of each other
                // Like stacking layers in Figma's layer panel
                ZStack {
                    // Bottom layer — the background card
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)

                    // Top layer — the content
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)

                        Text("Balance")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        Text("$4,280.50")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)

                Divider().background(.gray)

                // SECTION 4: Putting It Together — A Real Component
                // --------------------------------------------------
                // This is a notification card like you'd design in Figma.
                // Every line maps to something in the properties panel.

                SectionHeader(title: "Real Component", subtitle: "Putting it all together")

                // A beautiful notification card
                HStack(spacing: 14) {
                    // Icon container
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.blue)
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Received")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("From Alex · 2 min ago")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    // Amount
                    Text("+$240.00")
                        .font(.body.bold())
                        .foregroundStyle(.green)
                }
                .padding(16)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color(white: 0.08))
        .navigationTitle("Views & Modifiers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A reusable section header — this is a "component" in Figma terms
struct SectionHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        Lesson1_ViewsAndModifiers()
    }
    .preferredColorScheme(.dark)
}
