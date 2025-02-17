import SwiftUI

@main
struct DSAgameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1024, height: 768)  // Typical landscape size
    }
}