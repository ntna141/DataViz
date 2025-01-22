import SwiftUI

@main
struct DSAgameApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Initialize game data
        GameProgressionManager.shared.initializeGameLevels()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}