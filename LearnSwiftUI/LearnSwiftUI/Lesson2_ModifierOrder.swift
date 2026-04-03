import SwiftUI

// LESSON 2: Modifier Order Matters
// ==================================
// This is the #1 thing that confuses beginners.
// Modifiers WRAP the view from inside out.
// .padding() then .background() ≠ .background() then .padding()
//
// Think of it like this in Figma:
// - Each modifier creates a NEW frame around the previous one
// - .padding() adds space INSIDE the current frame
// - .background() fills the CURRENT frame
//
// So the order decides: does the background include the padding, or not?

struct Lesson2_ModifierOrder: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {

                // EXAMPLE 1: Padding THEN Background
                // -----------------------------------
                // The background includes the padding.
                // Like: Frame with padding → then fill that frame.

                SectionHeader(title: "Padding → Background", subtitle: "Background includes the padding")

                Text("Padding first")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .padding(20)                          // 1. Add 20pt space around text
                    .background(.blue)                    // 2. Fill that entire area (text + padding)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)

                // EXAMPLE 2: Background THEN Padding
                // -----------------------------------
                // The background only covers the text.
                // The padding is OUTSIDE the background.
                // Like: Fill the text frame → then add spacing outside.

                SectionHeader(title: "Background → Padding", subtitle: "Background only covers the text")

                Text("Background first")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .background(.blue)                    // 1. Fill just the text area
                    .padding(20)                          // 2. Add space OUTSIDE (background doesn't reach here)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)

                Divider().background(.gray)

                // EXAMPLE 3: The Double Background Trick
                // ----------------------------------------
                // You can use the same modifier multiple times!
                // This is like nesting frames in Figma.

                SectionHeader(title: "Multiple Backgrounds", subtitle: "Like nesting frames in Figma")

                Text("Layered")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .padding(12)                           // Inner padding
                    .background(.blue)                     // Inner background (blue)
                    .padding(4)                            // Gap between inner and outer
                    .background(.white.opacity(0.2))       // Outer background (border-like)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                Divider().background(.gray)

                // EXAMPLE 4: Side by Side Comparison
                // ------------------------------------
                // Same modifiers, different order. See the difference.

                SectionHeader(title: "Side by Side", subtitle: "Same modifiers, different results")

                HStack(spacing: 20) {
                    // Version A: padding → background → border
                    VStack(spacing: 8) {
                        Text("A")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .padding(20)
                            .background(.purple.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.purple, lineWidth: 2)
                            )

                        Text("pad → bg → border")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }

                    // Version B: background → padding → border
                    VStack(spacing: 8) {
                        Text("B")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                            .background(.purple.opacity(0.3))
                            .padding(20)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.purple, lineWidth: 2)
                            )

                        Text("bg → pad → border")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 20)

                Divider().background(.gray)

                // EXAMPLE 5: A Real-World Use Case
                // ----------------------------------
                // A tag/badge component. Modifier order makes it look right.

                SectionHeader(title: "Real Example: Tags", subtitle: "Modifier order makes these work")

                HStack(spacing: 10) {
                    TagView(text: "Design", color: .blue)
                    TagView(text: "Motion", color: .purple)
                    TagView(text: "Swift", color: .orange)
                }
                .padding(.horizontal, 20)

                // EXERCISE: Try This!
                // --------------------

                VStack(alignment: .leading, spacing: 8) {
                    Text("Try This:")
                        .font(.headline)
                        .foregroundStyle(.yellow)

                    Text("1. Swap .padding() and .background() in Example 1")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text("2. Add .shadow(radius: 10) before vs after .clipShape()")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text("3. In the tags, move .clipShape() before .padding()")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.yellow.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color(white: 0.08))
        .navigationTitle("Modifier Order")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A tag component — notice how modifier order creates the pill shape
struct TagView: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())         // 1. Style the text
            .foregroundStyle(color)         // 2. Color it
            .padding(.horizontal, 14)      // 3. Add horizontal space
            .padding(.vertical, 8)         // 4. Add vertical space
            .background(color.opacity(0.15))  // 5. Fill the padded area
            .clipShape(Capsule())          // 6. Clip the whole thing into a pill
    }
}

#Preview {
    NavigationStack {
        Lesson2_ModifierOrder()
    }
    .preferredColorScheme(.dark)
}
