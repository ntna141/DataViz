//
//  DSAgameApp.swift
//  DSAgame
//
//  Created by Anh Nguyen on 1/21/25.
//

import SwiftUI

@main
struct DSAgameApp: App {
    // Initialize the progression manager at the app level
    @StateObject private var progressionManager = ProgressionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressionManager) // Inject into environment
        }
    }
}
