import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Lesson 1: Views & Modifiers", destination: Lesson1_ViewsAndModifiers())
                NavigationLink("Lesson 2: Modifier Order Matters", destination: Lesson2_ModifierOrder())
                NavigationLink("Lesson 3: State — Making Things Interactive", destination: Lesson3_State())
            }
            .navigationTitle("Learn SwiftUI")
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
