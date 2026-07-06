// SuziPositionsDemoApp.swift
// App entry — renders the Positions screen full-screen, dark mode.

import SwiftUI

@main
struct SuziPositionsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PositionsScreen()
                .preferredColorScheme(.dark)
        }
    }
}
