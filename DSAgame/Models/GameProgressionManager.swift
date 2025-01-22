import Foundation
import CoreData

class GameProgressionManager {
    static let shared = GameProgressionManager()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    func initializeGameLevels() {
        // Check if levels already exist
        let fetchRequest: NSFetchRequest<LevelEntity> = LevelEntity.fetchRequest()
        
        do {
            let existingLevels = try context.fetch(fetchRequest)
            if existingLevels.isEmpty {
                print("Initializing game levels...")
                // Create initial levels
                for i in 1...10 {
                    let level = LevelEntity(context: context)
                    level.uuid = UUID()
                    level.number = Int32(i)
                    level.isUnlocked = i == 1
                    level.requiredStars = Int32((i - 1) * 3) // Each level requires 3 stars from previous level
                    
                    // Set specific topic and description for first level
                    if i == 1 {
                        level.topic = "Linked Lists"
                        level.desc = "Learn about linked lists and how to build them step by step."
                        
                        // Create visualization question for first level
                        let question = QuestionEntity(context: context)
                        question.uuid = UUID()
                        question.level = level
                        question.type = "visualization"
                        question.title = "Building a Linked List"
                        question.desc = "Learn how to build a linked list by following the code and completing the visualization"
                        question.difficulty = 1
                        question.isCompleted = false
                        question.stars = 0
                        question.attempts = 0
                    }
                }
                
                // Save the context to ensure levels and questions are created
                try context.save()
                print("Game levels initialized successfully")
                
                // Initialize visualization for first level's question
                VisualizationManager.shared.initializeExampleVisualization()
            } else {
                print("Game levels already exist, skipping initialization")
            }
        } catch {
            print("Error initializing game levels: \(error)")
        }
    }
    
    private func getQuestionType(_ number: Int) -> String {
        switch number {
            case 1: return "visualization"
            case 2: return "coding"
            case 3: return "fill_blank"
            case 4: return "matching"
            default: return "multiple_choice"
        }
    }
    
    func getLevel(_ number: Int) -> LevelEntity? {
        let fetchRequest: NSFetchRequest<LevelEntity> = LevelEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "number == %d", number)
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Error fetching level: \(error)")
            return nil
        }
    }
    
    func unlockLevel(_ number: Int) {
        guard let level = getLevel(number) else { return }
        level.isUnlocked = true
        
        do {
            try context.save()
        } catch {
            print("Error unlocking level: \(error)")
        }
    }
} 
