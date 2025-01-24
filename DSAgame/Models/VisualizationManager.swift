import Foundation
import CoreData

class VisualizationManager {
    static let shared = VisualizationManager()
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // Create a new visualization question from JSON data
    func createVisualization(for question: QuestionEntity, from jsonData: [String: Any]) {
        guard let visualization = jsonData["visualization"] as? [String: Any],
              let title = jsonData["title"] as? String,
              let description = jsonData["description"] as? String,
              let code = visualization["code"] as? [String],
              let dataStructureType = visualization["dataStructureType"] as? String,
              let steps = visualization["steps"] as? [[String: Any]] else {
            print("Invalid visualization JSON data")
            return
        }
        
        let visualizationEntity = VisualizationQuestionEntity(context: context)
        visualizationEntity.uuid = UUID()
        visualizationEntity.title = title
        visualizationEntity.desc = description
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
        for (index, stepData) in steps.enumerated() {
            guard let lineNumber = stepData["lineNumber"] as? Int,
                  let nodes = stepData["nodes"] as? [[String: Any]],
                  let connections = stepData["connections"] as? [[String: Any]] else {
                continue
            }
            
            let stepEntity = VisualizationStepEntity(context: context)
            stepEntity.uuid = UUID()
            stepEntity.orderIndex = Int32(index)
            stepEntity.codeHighlightedLine = Int32(lineNumber)
            stepEntity.lineComment = stepData["comment"] as? String
            stepEntity.userInputRequired = stepData["userInputRequired"] as? Bool ?? false
            stepEntity.availableElements = stepData["availableElements"] as? [String] ?? []
            stepEntity.question = visualizationEntity
            
            // Create nodes
            let nodeEntities = nodes.map { nodeData -> NodeEntity in
                let nodeEntity = NodeEntity(context: context)
                nodeEntity.uuid = UUID()
                nodeEntity.value = nodeData["value"] as? String ?? ""
                nodeEntity.label = nodeData["label"] as? String
                nodeEntity.isHighlighted = nodeData["isHighlighted"] as? Bool ?? false
                nodeEntity.positionX = 0 // Position will be calculated by the layout engine
                nodeEntity.positionY = 0
                nodeEntity.step = stepEntity
                return nodeEntity
            }
            
            // Create connections
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
                connectionEntity.isSelfPointing = connectionData["isSelfPointing"] as? Bool ?? false
                connectionEntity.style = connectionData["style"] as? String ?? "straight"
                connectionEntity.step = stepEntity
                connectionEntity.fromNode = nodeEntities[fromIndex]
                connectionEntity.toNode = nodeEntities[toIndex]
            }
        }
        
        // Save changes
        do {
            try context.save()
            print("Visualization saved successfully")
        } catch {
            print("Error saving visualization: \(error)")
        }
    }
    
    // Load visualization for a question
    func loadVisualization(for question: QuestionEntity) -> VisualizationQuestion? {
        guard let visualizationEntity = question.visualization else {
            return nil
        }
        
        // Load code lines
        let codeLines: [CodeLine] = {
            guard let codeSet = visualizationEntity.code as? Set<VisualizationQuestionLineEntity> else {
                return []
            }
            return codeSet
                .sorted(by: { $0.lineNumber < $1.lineNumber })
                .map { entity in
                    CodeLine(
                        number: Int(entity.lineNumber),
                        content: entity.content ?? "",
                        syntaxTokens: SyntaxParser.parse(entity.content ?? "")
                    )
                }
        }()
        
        // Load steps
        let steps: [VisualizationStep] = {
            guard let stepsSet = visualizationEntity.steps as? Set<VisualizationStepEntity> else {
                return []
            }
            return stepsSet
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map { stepEntity -> VisualizationStep in
                    // Convert nodes
                    let nodes = (stepEntity.nodes as? Set<NodeEntity>)?
                        .map { nodeEntity in
                            DSNode(
                                id: nodeEntity.uuid?.uuidString ?? UUID().uuidString,
                                value: nodeEntity.value ?? "",
                                isHighlighted: nodeEntity.isHighlighted,
                                label: nodeEntity.label
                            )
                        } ?? []
                    
                    // Convert connections
                    let connections = (stepEntity.connections as? Set<NodeConnectionEntity>)?
                        .map { connectionEntity in
                            DSConnection(
                                from: connectionEntity.fromNode?.uuid?.uuidString ?? UUID().uuidString,
                                to: connectionEntity.toNode?.uuid?.uuidString ?? UUID().uuidString,
                                label: connectionEntity.label,
                                isSelfPointing: connectionEntity.isSelfPointing,
                                isHighlighted: connectionEntity.isHighlighted,
                                style: DSConnection.ConnectionStyle(rawValue: connectionEntity.style ?? "straight") ?? .straight
                            )
                        } ?? []
                    
                    return VisualizationStep(
                        codeHighlightedLine: Int(stepEntity.codeHighlightedLine),
                        lineComment: stepEntity.lineComment,
                        dsState: nodes,
                        dsConnections: connections,
                        userInputRequired: stepEntity.userInputRequired,
                        availableElements: stepEntity.availableElements ?? []
                    )
                }
        }()
        
        // Get initial state from first step if available
        let initialState = steps.first?.dsState ?? []
        let initialConnections = steps.first?.dsConnections ?? []
        
        // Get layout type
        let layoutType = DataStructureView.LayoutType(rawValue: visualizationEntity.layoutType ?? "linkedList") ?? .linkedList
        
        return VisualizationQuestion(
            title: visualizationEntity.title ?? "",
            description: visualizationEntity.desc ?? "",
            code: codeLines,
            steps: steps,
            initialDSState: initialState,
            initialConnections: initialConnections,
            layoutType: layoutType
        )
    }
} 