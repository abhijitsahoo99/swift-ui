//
//  ArtifactTransitionApp.swift
//  ArtifactTransition
//

import SwiftUI

@main
struct ArtifactTransitionApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
                .preferredColorScheme(.dark)
        }
    }
}
