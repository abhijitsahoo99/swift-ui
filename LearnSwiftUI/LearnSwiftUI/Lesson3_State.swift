import SwiftUI

// LESSON 3: @State — The One Concept That Makes UI Interactive
// ==============================================================
//
// In Figma, you use variants + interactions to show different states.
// In SwiftUI, you use @State.
//
// @State is a variable that, when it changes, automatically re-renders the view.
// That's it. That's the whole concept.
//
// When you write:   @State private var isExpanded = false
// And then toggle:  isExpanded = true
// SwiftUI AUTOMATICALLY updates every part of the UI that uses `isExpanded`.
//
// No manual refresh. No "update frame". It just works.
// This is why SwiftUI is called "declarative" — you declare what the UI
// should look like for each state, and SwiftUI handles the transitions.

struct Lesson3_State: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {

                // EXAMPLE 1: A simple toggle
                Example1_SimpleTap()

                Divider().background(.gray)

                // EXAMPLE 2: Changing a value
                Example2_Counter()

                Divider().background(.gray)

                // EXAMPLE 3: Conditional UI (like Figma variants!)
                Example3_Variants()

                Divider().background(.gray)

                // EXAMPLE 4: Real component — Like/Heart button
                Example4_LikeButton()

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color(white: 0.08))
        .navigationTitle("State")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// EXAMPLE 1: Simple Tap
// ----------------------
// @State private var isOn = false
// Tapping the button toggles isOn between true/false.
// The circle color changes based on isOn.

struct Example1_SimpleTap: View {
    @State private var isOn = false       // ← This is STATE. It starts as false.

    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Simple Tap", subtitle: "@State toggles between true/false")

            // The UI reads the state and decides what to show
            Circle()
                .fill(isOn ? .green : .red)       // If isOn is true → green, else → red
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: isOn ? "checkmark" : "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }

            // This button CHANGES the state
            Button {
                isOn.toggle()     // ← This flips isOn: false→true or true→false
                // SwiftUI sees isOn changed, and re-renders the circle above
            } label: {
                Text(isOn ? "Turn Off" : "Turn On")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(isOn ? .green : .red)
                    .clipShape(Capsule())
            }

            Text("isOn = \(isOn ? "true" : "false")")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

// EXAMPLE 2: Counter
// -------------------
// State doesn't have to be true/false. It can be any value.
// Here, count is a number that increases when you tap.

struct Example2_Counter: View {
    @State private var count = 0      // ← STATE: starts at 0

    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Counter", subtitle: "State can be any value, not just true/false")

            // The count drives the number of circles shown
            HStack(spacing: 6) {
                ForEach(0..<min(count, 10), id: \.self) { _ in
                    Circle()
                        .fill(.blue)
                        .frame(width: 24, height: 24)
                }
            }
            .frame(height: 30)

            Text("\(count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                Button {
                    if count > 0 { count -= 1 }    // ← Change state: decrease
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }

                Button {
                    count += 1                        // ← Change state: increase
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(.blue)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// EXAMPLE 3: Conditional UI — Like Figma Variants
// -------------------------------------------------
// In Figma, you'd create variants: "default", "expanded", "selected"
// In SwiftUI, you use @State to switch between them.
// The ternary operator (condition ? valueA : valueB) is your variant picker.

struct Example3_Variants: View {
    @State private var selectedTab = 0     // ← Which tab is active

    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Variants", subtitle: "Like switching between Figma variants")

            // Tab bar — tapping changes selectedTab
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    let titles = ["Profile", "Activity", "Settings"]
                    let icons = ["person.fill", "chart.bar.fill", "gearshape.fill"]

                    Button {
                        selectedTab = index       // ← Change state to this tab
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: icons[index])
                                .font(.system(size: 18))

                            Text(titles[index])
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(selectedTab == index ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)

            // Content changes based on selectedTab
            // This is exactly like switching variants in Figma
            Group {
                switch selectedTab {
                case 0:
                    Label("Profile Content", systemImage: "person.fill")
                case 1:
                    Label("Activity Content", systemImage: "chart.bar.fill")
                default:
                    Label("Settings Content", systemImage: "gearshape.fill")
                }
            }
            .font(.body)
            .foregroundStyle(.white.opacity(0.6))
            .padding(.vertical, 20)
        }
    }
}

// EXAMPLE 4: Like Button — Real-World Component
// -----------------------------------------------
// A polished heart/like button.
// Two states: liked (true/false) and likeCount (number).
// Multiple pieces of state working together.

struct Example4_LikeButton: View {
    @State private var isLiked = false          // ← Is it liked?
    @State private var likeCount = 42           // ← How many likes?

    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Like Button", subtitle: "Multiple states working together")

            // A card with a like button
            VStack(spacing: 16) {
                // Gradient placeholder for an "image"
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                // Like row
                HStack {
                    Button {
                        isLiked.toggle()                          // ← Toggle liked state
                        likeCount += isLiked ? 1 : -1             // ← Update count based on state
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundStyle(isLiked ? .red : .gray)

                            Text("\(likeCount)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    Button {
                        // Share action — we'll add functionality later
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(16)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 20)

            // Show current state values
            HStack(spacing: 20) {
                Text("isLiked = \(isLiked ? "true" : "false")")
                Text("likeCount = \(likeCount)")
            }
            .font(.caption)
            .foregroundStyle(.gray)
        }
    }
}

#Preview {
    NavigationStack {
        Lesson3_State()
    }
    .preferredColorScheme(.dark)
}
