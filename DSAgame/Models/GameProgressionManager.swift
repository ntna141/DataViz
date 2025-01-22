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
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                return // Levels already initialized
            }
            
            // Create 100 levels
            for levelNumber in 1...100 {
                let level = LevelEntity(context: context)
                level.uuid = UUID()
                level.number = Int32(levelNumber)
                level.isUnlocked = levelNumber == 1 // Only first level is unlocked
                level.topic = "Topic \(levelNumber)" // You can customize this later
                level.desc = "Level \(levelNumber) description" // You can customize this later
                level.requiredStars = Int32((levelNumber - 1) * 8) // Requires previous level completion
                
                // Create 4 questions for each level
                for questionNumber in 1...4 {
                    let question = QuestionEntity(context: context)
                    question.uuid = UUID()
                    question.title = "Question \(questionNumber)"
                    question.desc = "Question \(questionNumber) description"
                    question.type = getQuestionType(questionNumber) // Different types of questions
                    question.difficulty = 1 // We'll remove this since we're using types instead
                    question.isCompleted = false
                    question.stars = 0
                    question.attempts = 0
                    question.level = level
                }
            }
            
            try context.save()
            
        } catch {
            print("Error initializing levels: \(error)")
        }
    }
    
    private func getQuestionType(_ number: Int) -> String {
        switch number {
            case 1: return "multiple_choice"
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
