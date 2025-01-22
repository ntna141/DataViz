import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add any sample data here for previews
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DSAGame")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }
        
        // Enable debug mode for development
        #if DEBUG
        // Only reset if environment variable is set
        if ProcessInfo.processInfo.environment["RESET_CORE_DATA"] == "1" {
            resetStore()
        }
        #endif
    }
    
    // Debug helper to reset store
    func resetStore() {
        // Get the store URL
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            print("Core Data store reset successfully")
        } catch {
            print("Failed to reset Core Data store: \(error)")
        }
    }
} 
