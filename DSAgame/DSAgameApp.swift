import SwiftUI

@main
struct DSAgameApp: App {
    init() {
        // Reset the guide seen status to false on app launch
        UserDefaults.standard.set(false, forKey: "hasSeenDataStructureGuide")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1024, height: 768)  // Typical landscape size
    }
}