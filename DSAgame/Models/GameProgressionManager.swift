import Foundation
import CoreData

class GameProgressionManager {
    static let shared = GameProgressionManager()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    private func loadLevelData() -> LevelData? {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json") else {
            print("Could not find levels.json in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(LevelData.self, from: data)
        } catch {
            print("Error loading level data: \(error)")
            return nil
        }
    }
    
    func initializeGameLevels() {
        // Check if levels already exist
        let fetchRequest: NSFetchRequest<LevelEntity> = LevelEntity.fetchRequest()
        
        do {
            let existingLevels = try context.fetch(fetchRequest)
            print("Found \(existingLevels.count) existing levels")
            
            let shouldReset = ProcessInfo.processInfo.environment["RESET_GAME_DATA"] == "1"
            print("RESET_GAME_DATA environment variable is \(ProcessInfo.processInfo.environment["RESET_GAME_DATA"] ?? "not set")")
            
            if existingLevels.isEmpty || shouldReset {
                if shouldReset {
                    print("Resetting game data...")
                    // Delete existing data
                    for level in existingLevels {
                        print("Deleting level \(level.number) with \(level.questions?.count ?? 0) questions")
                        context.delete(level)
                    }
                    try context.save()
                    print("Existing data deleted successfully")
                }
                
                print("Initializing game levels...")
                guard let levelData = loadLevelData() else {
                    print("Failed to load level data from levels.json")
                    return
                }
                print("Loaded \(levelData.levels.count) levels from JSON")
                
                // Create levels from JSON data
                for levelSpec in levelData.levels {
                    print("Creating level \(levelSpec.number): \(levelSpec.topic)")
                    let level = LevelEntity(context: context)
                    level.uuid = UUID()
                    level.number = Int32(levelSpec.number)
                    level.isUnlocked = true  // All levels start unlocked
                    level.topic = levelSpec.topic
                    level.desc = levelSpec.description
                    
                    // Create questions
                    for questionSpec in levelSpec.questions {
                        print("Creating question: \(questionSpec.title) of type \(questionSpec.type)")
                        let question = QuestionEntity(context: context)
                        question.uuid = UUID()
                        question.level = level
                        question.type = questionSpec.type
                        question.title = questionSpec.title
                        question.desc = questionSpec.description
                        question.difficulty = Int16(questionSpec.difficulty)
                        question.isCompleted = false
                        question.stars = 0
                        question.attempts = 0
                        
                        // Save to ensure question has an ID
                        try context.save()
                        print("Question saved successfully")
                        
                        // Create visualization if present
                        if let visualizationSpec = questionSpec.visualization {
                            print("Creating visualization with \(visualizationSpec.steps.count) steps")
                            createVisualization(for: question, from: visualizationSpec)
                        }
                    }
                }
                
                try context.save()
                print("Game levels initialized successfully")
                
                // Verify initialization
                let verifyLevels = try context.fetch(fetchRequest)
                print("Verification: Found \(verifyLevels.count) levels after initialization")
                for level in verifyLevels {
                    print("Level \(level.number): \(level.questions?.count ?? 0) questions")
                    if let questions = level.questions?.allObjects as? [QuestionEntity] {
                        for question in questions {
                            print("  - Question: \(question.title ?? ""), Visualization: \(question.visualization != nil ? "Yes" : "No")")
                        }
                    }
                }
            } else {
                print("Game levels already exist, skipping initialization")
                print("To force reset, set RESET_GAME_DATA=1 in environment variables")
            }
        } catch {
            print("Error initializing game levels: \(error)")
        }
    }
    
    private func createVisualization(for question: QuestionEntity, from spec: LevelData.Visualization) {
        let visualization = VisualizationQuestionEntity(context: context)
        visualization.uuid = UUID()
        visualization.title = question.title
        visualization.desc = question.desc
        visualization.layoutType = spec.dataStructureType
        visualization.question = question
        question.visualization = visualization
        
        // Create code lines
        for (index, line) in spec.code.enumerated() {
            let codeLine = VisualizationQuestionLineEntity(context: context)
            codeLine.uuid = UUID()
            codeLine.lineNumber = Int32(index + 1)
            codeLine.content = line
            codeLine.question = visualization
        }
        
        // Create steps
        for (index, stepSpec) in spec.steps.enumerated() {
            let stepEntity = VisualizationStepEntity(context: context)
            stepEntity.uuid = UUID()
            stepEntity.orderIndex = Int32(index)
            stepEntity.codeHighlightedLine = Int32(stepSpec.lineNumber)
            stepEntity.lineComment = stepSpec.comment
            stepEntity.hint = stepSpec.hint
            stepEntity.isMultipleChoice = stepSpec.isMultipleChoice ?? false
            stepEntity.multipleChoiceAnswers = stepSpec.multipleChoiceAnswers ?? []
            stepEntity.multipleChoiceCorrectAnswer = stepSpec.multipleChoiceCorrectAnswer ?? ""
            stepEntity.userInputRequired = stepSpec.isMultipleChoice ?? false || 
                                         stepSpec.userInputRequired || 
                                         stepSpec.availableElements != nil
            
            print("[Step \(index)] Raw availableElements from JSON: \(String(describing: stepSpec.availableElements))")
            // Only set availableElements if it's explicitly present in the JSON
            if let elements = stepSpec.availableElements {
                stepEntity.availableElements = elements
                print("[Step \(index)] Set availableElements to: \(elements)")
            } else {
                print("[Step \(index)] availableElements not present in JSON, leaving as nil")
            }
            stepEntity.question = visualization
            
            // Create node IDs based on the actual number of nodes
            let nodeIDs = stepSpec.nodes.map { _ in UUID() }
            
            // Create nodes with consistent IDs
            let nodeEntities = zip(stepSpec.nodes.enumerated(), nodeIDs).map { (indexedNode, nodeID) -> NodeEntity in
                let (index, nodeSpec) = indexedNode
                let nodeEntity = NodeEntity(context: context)
                nodeEntity.uuid = nodeID
                nodeEntity.value = nodeSpec.value
                nodeEntity.isHighlighted = nodeSpec.isHighlighted ?? false
                nodeEntity.label = nodeSpec.label
                nodeEntity.orderIndex = Int32(index)  // Set the order index based on the enumerated index
                nodeEntity.positionX = 0 // Position will be calculated by the layout engine
                nodeEntity.positionY = 0
                nodeEntity.step = stepEntity
                
                return nodeEntity
            }
            
            // Create connections using node indices
            if let connections = stepSpec.connections {
                for connectionSpec in connections {
                    let connectionEntity = NodeConnectionEntity(context: context)
                    connectionEntity.uuid = UUID()
                    connectionEntity.label = connectionSpec.label
                    connectionEntity.isHighlighted = connectionSpec.isHighlighted ?? false
                    connectionEntity.isSelfPointing = false
                    connectionEntity.style = connectionSpec.style ?? "straight"
                    connectionEntity.step = stepEntity
                    
                    // Link to nodes using indices
                    connectionEntity.fromNode = nodeEntities[connectionSpec.from]
                    connectionEntity.toNode = nodeEntities[connectionSpec.to]
                }
            }
        }
        
        do {
            try context.save()
            print("Visualization created successfully")
        } catch {
            print("Error creating visualization: \(error)")
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
    
    func isLevelCompleted(_ number: Int) -> Bool {
        guard let level = getLevel(number) else {
            print("Level \(number) not found")
            return false
        }
        guard let questions = level.questions?.allObjects as? [QuestionEntity] else {
            print("No questions found for level \(number)")
            return false
        }
        
        let completed = !questions.isEmpty && questions.allSatisfy { $0.isCompleted }
        print("Level \(number) completion status: \(completed)")
        print("Questions completed: \(questions.filter { $0.isCompleted }.count)/\(questions.count)")
        questions.forEach { question in
            print("  - Question '\(question.title ?? "Untitled")': \(question.isCompleted ? "Completed" : "Incomplete")")
            print("    Stars: \(question.stars), Attempts: \(question.attempts)")
        }
        return completed
    }
    
    func unlockLevel(_ number: Int) {
        // For level 2 and above, check if previous level is completed
        if number > 1 {
            print("Checking completion status of level \(number - 1) before unlocking level \(number)")
            if !isLevelCompleted(number - 1) {
                print("Cannot unlock level \(number): Previous level not completed")
                return
            }
        }
        
        guard let level = getLevel(number) else {
            print("Failed to unlock level \(number): Level not found")
            return
        }
        level.isUnlocked = true
        print("Level \(number) unlocked successfully")
        
        do {
            try context.save()
        } catch {
            print("Error unlocking level: \(error)")
        }
    }
    
    func markQuestionCompleted(_ questionId: UUID) {
        let fetchRequest: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", questionId as CVarArg)
        
        do {
            if let question = try context.fetch(fetchRequest).first {
                question.isCompleted = true
                question.stars = 3  // Or however many stars you want to award
                try context.save()
                print("Question \(question.title ?? "") marked as completed")
                
                // Check if this completes the level
                if let level = question.level {
                    print("Checking if level \(level.number) is now completed")
                    if isLevelCompleted(Int(level.number)) {
                        // If the level is completed, unlock the next level
                        let nextLevelNumber = Int(level.number) + 1
                        print("Level \(level.number) completed, unlocking level \(nextLevelNumber)")
                        unlockLevel(nextLevelNumber)
                    }
                }
            }
        } catch {
            print("Error marking question as completed: \(error)")
        }
    }
    
    func updateLevelLocks() {
        let fetchRequest: NSFetchRequest<LevelEntity> = LevelEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LevelEntity.number, ascending: true)]
        
        do {
            let levels = try context.fetch(fetchRequest)
            print("Checking level locks...")
            
            for level in levels {
                let levelNumber = Int(level.number)
                if levelNumber == 1 {
                    // First level is always unlocked
                    level.isUnlocked = true
                    print("Level 1 is always unlocked")
                } else {
                    // Check if previous level is completed
                    let previousLevelCompleted = isLevelCompleted(levelNumber - 1)
                    print("Level \(levelNumber) previous level completed: \(previousLevelCompleted)")
                    level.isUnlocked = previousLevelCompleted
                }
            }
            
            try context.save()
            print("Level locks updated")
            
            // Print current lock status
            for level in levels {
                print("Level \(level.number) unlock status: \(level.isUnlocked)")
            }
        } catch {
            print("Error updating level locks: \(error)")
        }
    }
} 
