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
                    level.isUnlocked = levelSpec.number == 1
                    level.requiredStars = Int32(levelSpec.requiredStars)
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
            stepEntity.userInputRequired = stepSpec.userInputRequired
            stepEntity.availableElements = stepSpec.availableElements
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
                
                print("Creating node at index \(nodeEntity.orderIndex):")
                print("  - Value: '\(nodeEntity.value ?? "")'")
                print("  - Label: \(nodeEntity.label ?? "none")")
                print("  - UUID: \(nodeEntity.uuid?.uuidString ?? "unknown")")
                
                return nodeEntity
            }
            
            // Create connections using node indices
            for connectionSpec in stepSpec.connections {
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
                
                print("Created connection: \(connectionSpec.from) -> \(connectionSpec.to)")
                print("  - From node value: '\(nodeEntities[connectionSpec.from].value ?? "")'")
                print("  - To node value: '\(nodeEntities[connectionSpec.to].value ?? "")'")
                print("  - Style: \(connectionEntity.style ?? "straight")")
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
