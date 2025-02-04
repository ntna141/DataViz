import Foundation
import CoreData
import SwiftUI

class VisualizationManager {
    static let shared = VisualizationManager()
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // Draw an arrow between two cells
    func drawArrow(from fromIndex: Int, to toIndex: Int, label: String? = nil, style: ConnectionStyle = .straight, inStep stepIndex: Int, forQuestion question: QuestionEntity) {
        
        guard let visualization = question.visualization,
              let steps = visualization.steps as? Set<VisualizationStepEntity>,
              let targetStep = steps.first(where: { $0.orderIndex == stepIndex }),
              let nodes = targetStep.nodes as? Set<NodeEntity> else {
            return
        }
        
        // Get ordered nodes
        let orderedNodes = Array(nodes)
            .sorted { $0.orderIndex < $1.orderIndex }
            .sorted { n1, n2 in
                if n1.label == "head" { return true }
                if n2.label == "head" { return false }
                return n1.orderIndex < n2.orderIndex
            }
        
        guard fromIndex < orderedNodes.count && toIndex < orderedNodes.count else {
            print("Node indices out of bounds")
            return
        }
        
        // Create the connection
        let connection = NodeConnectionEntity(context: context)
        connection.uuid = UUID()
        connection.label = label
        connection.style = style.rawValue
        connection.step = targetStep
        connection.fromNode = orderedNodes[fromIndex]
        connection.toNode = orderedNodes[toIndex]
        
        // Save changes
        do {
            try context.save()
            print("Arrow drawn successfully")
        } catch {
            print("Error saving arrow: \(error)")
        }
    }
    
    // Remove an arrow between two cells
    func removeArrow(from fromIndex: Int, to toIndex: Int, inStep stepIndex: Int, forQuestion question: QuestionEntity) {
        print("\n=== Removing Arrow from Data Structure ===")
        print("From Cell Index: \(fromIndex)")
        print("To Cell Index: \(toIndex)")
        print("Step Index: \(stepIndex)")
        
        guard let visualization = question.visualization,
              let steps = visualization.steps as? Set<VisualizationStepEntity>,
              let targetStep = steps.first(where: { $0.orderIndex == stepIndex }),
              let nodes = targetStep.nodes as? Set<NodeEntity>,
              let connections = targetStep.connections as? Set<NodeConnectionEntity> else {
            print("Failed to find target step, nodes, or connections")
            return
        }
        
        // Get ordered nodes
        let orderedNodes = Array(nodes)
            .sorted { $0.orderIndex < $1.orderIndex }
            .sorted { n1, n2 in
                if n1.label == "head" { return true }
                if n2.label == "head" { return false }
                return n1.orderIndex < n2.orderIndex
            }
        
        guard fromIndex < orderedNodes.count && toIndex < orderedNodes.count else {
            print("Node indices out of bounds")
            return
        }
        
        // Find and remove the connection
        if let connection = connections.first(where: { 
            $0.fromNode == orderedNodes[fromIndex] && $0.toNode == orderedNodes[toIndex] 
        }) {
            context.delete(connection)
            
            // Save changes
            do {
                try context.save()
                print("Arrow removed successfully")
            } catch {
                print("Error removing arrow: \(error)")
            }
        } else {
            print("No connection found between specified nodes")
        }
    }
    
    // Set value for a cell
    func setValue(_ value: String, forCellAtIndex index: Int, inStep stepIndex: Int, forQuestion question: QuestionEntity) {
        print("\n=== Setting Value in Data Structure ===")
        print("Value: '\(value)'")
        print("Cell Index: \(index)")
        print("Step Index: \(stepIndex)")
        
        guard let visualization = question.visualization,
              let steps = visualization.steps as? Set<VisualizationStepEntity>,
              let targetStep = steps.first(where: { $0.orderIndex == stepIndex }),
              let nodes = targetStep.nodes as? Set<NodeEntity> else {
            print("Failed to find target step or nodes")
            return
        }
        
        // Get ordered nodes
        let orderedNodes = Array(nodes)
            .sorted { $0.orderIndex < $1.orderIndex }
            .sorted { n1, n2 in
                if n1.label == "head" { return true }
                if n2.label == "head" { return false }
                return n1.orderIndex < n2.orderIndex
            }
        
        guard index < orderedNodes.count else {
            print("Cell index out of bounds")
            return
        }
        
        // Update the cell value
        let targetNode = orderedNodes[index]
        targetNode.value = value
        
        print("Updated cell:")
        print("  - Value: '\(targetNode.value ?? "")'")
        print("  - Label: \(targetNode.label ?? "none")")
        print("  - Order Index: \(targetNode.orderIndex)")
        
        // Save changes
        do {
            try context.save()
            print("Value set successfully")
        } catch {
            print("Error saving value: \(error)")
        }
    }
    
    // Create a new visualization question from JSON data
    func createVisualization(for question: QuestionEntity, from jsonData: [String: Any]) {
        print("\n=== Creating Visualization from JSON ===")
        print("Raw JSON data:")
        print(jsonData)
        
        guard let visualization = jsonData["visualization"] as? [String: Any],
              let title = jsonData["title"] as? String,
              let description = jsonData["description"] as? String,
              let hint = jsonData["hint"] as? String,
              let review = jsonData["review"] as? String,
              let code = visualization["code"] as? [String],
              let dataStructureType = visualization["dataStructureType"] as? String,
              let steps = visualization["steps"] as? [[String: Any]] else {
            print("Invalid visualization JSON data")
            return
        }
        
        print("\nParsed visualization data:")
        print("Title: \(title)")
        print("Description: \(description)")
        print("Hint: \(hint)")
        print("Review: \(review)")
        print("Data structure type: \(dataStructureType)")
        print("\nSteps:")
        for (index, stepData) in steps.enumerated() {
            print("\nStep \(index):")
            print(stepData)
        }
        
        let visualizationEntity = VisualizationQuestionEntity(context: context)
        visualizationEntity.uuid = UUID()
        visualizationEntity.title = title
        visualizationEntity.desc = description
        visualizationEntity.hint = hint
        visualizationEntity.review = review
        visualizationEntity.question = question
        visualizationEntity.layoutType = dataStructureType
        question.visualization = visualizationEntity
        
        // Create code lines
        for (index, line) in code.enumerated() {
            let codeLine = VisualizationQuestionLineEntity(context: context)
            codeLine.uuid = UUID()
            codeLine.lineNumber = Int32(index + 1)
            codeLine.content = line
            codeLine.question = visualizationEntity
        }
        
        // Create steps
        print("\nCreating step entities:")
        for (index, stepData) in steps.enumerated() {
            guard let lineNumber = stepData["lineNumber"] as? Int,
                  let nodes = stepData["nodes"] as? [[String: Any]],
                  let connections = stepData["connections"] as? [[String: Any]] else {
                print("Failed to load required step data for step \(index)")
                continue
            }
            
            print("\nProcessing step \(index):")
            print("Line number: \(lineNumber)")
            print("Comment: \(stepData["comment"] as? String ?? "none")")
            print("User input required: \(stepData["userInputRequired"] as? Bool ?? false)")
            
            // Print raw multiple choice data from JSON with type information
            print("\nRaw multiple choice data from JSON for step \(index):")
            print("Raw stepData keys: \(stepData.keys)")
            if let rawIsMultipleChoice = stepData["isMultipleChoice"] {
                print("Raw isMultipleChoice value: \(rawIsMultipleChoice)")
                print("Raw isMultipleChoice type: \(type(of: rawIsMultipleChoice))")
            } else {
                print("isMultipleChoice key not found in stepData")
            }
            
            if let rawAnswers = stepData["multipleChoiceAnswers"] {
                print("Raw multipleChoiceAnswers value: \(rawAnswers)")
                print("Raw multipleChoiceAnswers type: \(type(of: rawAnswers))")
            } else {
                print("multipleChoiceAnswers key not found in stepData")
            }
            
            if let rawCorrectAnswer = stepData["multipleChoiceCorrectAnswer"] {
                print("Raw multipleChoiceCorrectAnswer value: \(rawCorrectAnswer)")
                print("Raw multipleChoiceCorrectAnswer type: \(type(of: rawCorrectAnswer))")
            } else {
                print("multipleChoiceCorrectAnswer key not found in stepData")
            }
            
            let stepEntity = VisualizationStepEntity(context: context)
            stepEntity.uuid = UUID()
            stepEntity.orderIndex = Int32(index)
            stepEntity.codeHighlightedLine = Int32(lineNumber)
            stepEntity.lineComment = stepData["comment"] as? String
            stepEntity.userInputRequired = stepData["userInputRequired"] as? Bool ?? false
            
            // Only set availableElements if it's explicitly present in the JSON
            if let availableElements = stepData["availableElements"] as? [String] {
                stepEntity.availableElements = availableElements
                print("Step \(index): availableElements set to \(availableElements)")
            } else {
                stepEntity.availableElements = nil
                print("Step \(index): availableElements not present in JSON")
            }
            
            // Add multiple choice fields with explicit type checking
            if let isMultipleChoice = stepData["isMultipleChoice"] as? Bool {
                stepEntity.isMultipleChoice = isMultipleChoice
                print("Set isMultipleChoice to: \(isMultipleChoice) (from Bool)")
            } else if let isMultipleChoiceNumber = stepData["isMultipleChoice"] as? NSNumber {
                stepEntity.isMultipleChoice = isMultipleChoiceNumber.boolValue
                print("Set isMultipleChoice to: \(isMultipleChoiceNumber.boolValue) (from NSNumber)")
            } else if let isMultipleChoiceInt = stepData["isMultipleChoice"] as? Int {
                stepEntity.isMultipleChoice = isMultipleChoiceInt != 0
                print("Set isMultipleChoice to: \(isMultipleChoiceInt != 0) (from Int)")
            } else {
                print("Raw isMultipleChoice value: \(String(describing: stepData["isMultipleChoice"]))")
                print("Raw isMultipleChoice type: \(String(describing: type(of: stepData["isMultipleChoice"])))")
                stepEntity.isMultipleChoice = false
                print("Could not convert isMultipleChoice to Bool, defaulting to false")
            }
            
            if let multipleChoiceAnswers = stepData["multipleChoiceAnswers"] as? [String] {
                stepEntity.multipleChoiceAnswers = multipleChoiceAnswers
                print("Set multipleChoiceAnswers to: \(multipleChoiceAnswers)")
            } else if let rawAnswers = stepData["multipleChoiceAnswers"] {
                print("Raw multipleChoiceAnswers value: \(rawAnswers)")
                print("Raw multipleChoiceAnswers type: \(type(of: rawAnswers))")
                stepEntity.multipleChoiceAnswers = []
            } else {
                stepEntity.multipleChoiceAnswers = []
                print("No multipleChoiceAnswers found, defaulting to empty array")
            }
            
            if let multipleChoiceCorrectAnswer = stepData["multipleChoiceCorrectAnswer"] as? String {
                stepEntity.multipleChoiceCorrectAnswer = multipleChoiceCorrectAnswer
                print("Set multipleChoiceCorrectAnswer to: \(multipleChoiceCorrectAnswer)")
            } else if let rawCorrectAnswer = stepData["multipleChoiceCorrectAnswer"] {
                print("Raw multipleChoiceCorrectAnswer value: \(rawCorrectAnswer)")
                print("Raw multipleChoiceCorrectAnswer type: \(type(of: rawCorrectAnswer))")
                stepEntity.multipleChoiceCorrectAnswer = ""
            } else {
                stepEntity.multipleChoiceCorrectAnswer = ""
                print("No multipleChoiceCorrectAnswer found, defaulting to empty string")
            }
            
            print("\nVerifying step entity multiple choice data:")
            print("  - isMultipleChoice: \(stepEntity.isMultipleChoice)")
            print("  - multipleChoiceAnswers: \(stepEntity.multipleChoiceAnswers ?? [])")
            print("  - multipleChoiceCorrectAnswer: \(stepEntity.multipleChoiceCorrectAnswer ?? "")")
            
            stepEntity.question = visualizationEntity
            
            // Create nodes with consistent IDs
            let nodeEntities = nodes.enumerated().map { index, nodeData -> NodeEntity in
                let nodeEntity = NodeEntity(context: context)
                nodeEntity.uuid = UUID()
                nodeEntity.value = nodeData["value"] as? String
                nodeEntity.label = nodeData["label"] as? String
                nodeEntity.orderIndex = Int32(index)  // Store the array index
                nodeEntity.step = stepEntity
                
                // Print node details for debugging
                print("Creating node at index \(index):")
                print("  - Value: '\(nodeEntity.value ?? "")'")
                print("  - Label: \(nodeEntity.label ?? "none")")
                print("  - Order Index: \(nodeEntity.orderIndex)")
                
                return nodeEntity
            }
            
            // Create connections using node indices
            for connectionData in connections {
                guard let fromIndex = connectionData["from"] as? Int,
                      let toIndex = connectionData["to"] as? Int,
                      fromIndex < nodeEntities.count,
                      toIndex < nodeEntities.count else {
                    continue
                }
                
                let connectionEntity = NodeConnectionEntity(context: context)
                connectionEntity.uuid = UUID()
                connectionEntity.label = connectionData["label"] as? String
                connectionEntity.isHighlighted = connectionData["isHighlighted"] as? Bool ?? false
                connectionEntity.isSelfPointing = false
                connectionEntity.style = connectionData["style"] as? String ?? "straight"
                connectionEntity.step = stepEntity
                connectionEntity.fromNode = nodeEntities[fromIndex]
                connectionEntity.toNode = nodeEntities[toIndex]
                
                print("Created connection: \(fromIndex) -> \(toIndex)")
            }
        }
        
        // Save changes
        do {
            try context.save()
            print("\nVisualization saved successfully")
        } catch {
            print("Error saving visualization: \(error)")
        }
    }
    
    // Load visualization for a question
    func loadVisualization(for question: QuestionEntity) -> VisualizationQuestion? {
        print("\n=== Loading Visualization ===")
        guard let visualizationEntity = question.visualization else {
            print("No visualization found")
            return nil
        }
        
        print("\nVisualization found:")
        print("Title: \(visualizationEntity.title ?? "")")
        print("Description: \(visualizationEntity.desc ?? "")")
        print("Layout type: \(visualizationEntity.layoutType ?? "")")
        
        // Load code lines
        let codeLines: [CodeLine] = {
            guard let codeSet = visualizationEntity.code as? Set<VisualizationQuestionLineEntity> else {
                return []
            }
            let lines = codeSet
                .sorted(by: { $0.lineNumber < $1.lineNumber })
                .map { entity in
                    CodeLine(
                        number: Int(entity.lineNumber),
                        content: entity.content ?? "",
                        syntaxTokens: SyntaxParser.parse(entity.content ?? "")
                    )
                }
            print("\nLoaded code lines:")
            for line in lines {
                print("Line \(line.number): \(line.content)")
            }
            return lines
        }()
        
        // Load steps
        let steps: [VisualizationStep] = {
            guard let stepsSet = visualizationEntity.steps as? Set<VisualizationStepEntity> else {
                return []
            }
            let loadedSteps = stepsSet
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map { stepEntity -> VisualizationStep in
                    print("\n=== Loading Step Entity \(stepEntity.orderIndex) ===")
                    print("Step Entity Details:")
                    print("  - UUID: \(stepEntity.uuid?.uuidString ?? "nil")")
                    print("  - Line highlighted: \(stepEntity.codeHighlightedLine)")
                    print("  - User input required: \(stepEntity.userInputRequired)")
                    print("  - Available elements: \(String(describing: stepEntity.availableElements))")
                    
                    // Load nodes in order based on stored index
                    let allNodes = stepEntity.nodes as? Set<NodeEntity> ?? Set()
                    let orderedNodes = Array(allNodes)
                        .sorted { $0.orderIndex < $1.orderIndex }
                        .sorted { n1, n2 in
                            // Ensure head node is always first
                            if n1.label == "head" { return true }
                            if n2.label == "head" { return false }
                            return n1.orderIndex < n2.orderIndex
                        }
                    
                    // Convert to BasicCells
                    let cells = orderedNodes.map { nodeEntity -> BasicCell in
                        return BasicCell(
                            value: nodeEntity.value ?? "",
                            isHighlighted: nodeEntity.isHighlighted,
                            label: nodeEntity.label
                        )
                    }
                    
                    // Convert connections
                    let connections = stepEntity.connections as? Set<NodeConnectionEntity> ?? Set()
                    let loadedConnections = connections.map { connectionEntity -> BasicConnection in
                        guard let fromNode = connectionEntity.fromNode,
                              let toNode = connectionEntity.toNode,
                              let fromId = fromNode.uuid?.uuidString,
                              let toId = toNode.uuid?.uuidString else {
                            return BasicConnection(
                                fromCellId: UUID().uuidString,
                                toCellId: UUID().uuidString
                            )
                        }
                        
                        let connection = BasicConnection(
                            fromCellId: fromId,
                            toCellId: toId,
                            label: connectionEntity.label,
                            isHighlighted: connectionEntity.isHighlighted,
                            style: ConnectionStyle(rawValue: connectionEntity.style ?? "straight") ?? .straight
                        )
                        print("Connection: \(connection.fromCellId) -> \(connection.toCellId)")
                        return connection
                    }
                    
                    return VisualizationStep(
                        codeHighlightedLine: Int(stepEntity.codeHighlightedLine),
                        lineComment: stepEntity.lineComment,
                        hint: stepEntity.hint,
                        cells: cells,
                        connections: loadedConnections,
                        userInputRequired: stepEntity.userInputRequired,
                        availableElements: stepEntity.availableElements,
                        isMultipleChoice: stepEntity.isMultipleChoice,
                        multipleChoiceAnswers: stepEntity.multipleChoiceAnswers ?? [],
                        multipleChoiceCorrectAnswer: stepEntity.multipleChoiceCorrectAnswer ?? ""
                    )
                }
            return loadedSteps
        }()
        
        return VisualizationQuestion(
            title: visualizationEntity.title ?? "",
            description: visualizationEntity.desc ?? "",
            hint: visualizationEntity.hint ?? "",
            review: visualizationEntity.review ?? "",
            code: codeLines,
            steps: steps,
            initialCells: [],
            initialConnections: [],
            layoutType: DataStructureLayoutType(rawValue: visualizationEntity.layoutType ?? "linkedList") ?? .linkedList
        )
    }
} 
