import Foundation
import CoreData

class VisualizationManager {
    static let shared = VisualizationManager()
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // Create a new visualization question
    func createVisualization(for question: QuestionEntity,
                           title: String,
                           description: String,
                           code: [String],
                           steps: [(lineNumber: Int, comment: String?, nodes: [DSNode], connections: [DSConnection], userInputRequired: Bool, availableElements: [String])]) {
        let visualization = VisualizationQuestionEntity(context: context)
        visualization.uuid = UUID()
        visualization.title = title
        visualization.desc = description
        visualization.question = question
        
        // Create code lines
        for (index, line) in code.enumerated() {
            let codeLine = VisualizationQuestionLineEntity(context: context)
            codeLine.uuid = UUID()
            codeLine.lineNumber = Int32(index + 1)
            codeLine.content = line
            codeLine.question = visualization
        }
        
        // Create steps
        for (index, step) in steps.enumerated() {
            let stepEntity = VisualizationStepEntity(context: context)
            stepEntity.uuid = UUID()
            stepEntity.orderIndex = Int32(index)
            stepEntity.codeHighlightedLine = Int32(step.lineNumber)
            stepEntity.lineComment = step.comment
            stepEntity.userInputRequired = step.userInputRequired
            stepEntity.availableElements = step.availableElements
            stepEntity.question = visualization
            
            // Create nodes
            let nodeEntities = step.nodes.map { node -> NodeEntity in
                let nodeEntity = NodeEntity(context: context)
                nodeEntity.uuid = UUID()
                nodeEntity.value = node.value
                nodeEntity.label = node.label
                nodeEntity.isHighlighted = node.isHighlighted
                nodeEntity.positionX = Double(node.position.x)
                nodeEntity.positionY = Double(node.position.y)
                nodeEntity.step = stepEntity
                return nodeEntity
            }
            
            // Create connections
            for connection in step.connections {
                let connectionEntity = NodeConnectionEntity(context: context)
                connectionEntity.uuid = UUID()
                connectionEntity.label = connection.label
                connectionEntity.isHighlighted = connection.isHighlighted
                connectionEntity.isSelfPointing = connection.isSelfPointing
                connectionEntity.style = connection.style.rawValue
                connectionEntity.step = stepEntity
                
                // Find corresponding nodes
                if let fromNode = nodeEntities.first(where: { $0.value == step.nodes.first(where: { $0.id == connection.from })?.value }),
                   let toNode = nodeEntities.first(where: { $0.value == step.nodes.first(where: { $0.id == connection.to })?.value }) {
                    connectionEntity.fromNode = fromNode
                    connectionEntity.toNode = toNode
                }
            }
        }
        
        // Save changes
        do {
            try context.save()
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
                                value: nodeEntity.value ?? "",
                                isHighlighted: nodeEntity.isHighlighted,
                                label: nodeEntity.label,
                                position: CGPoint(
                                    x: nodeEntity.positionX,
                                    y: nodeEntity.positionY
                                )
                            )
                        } ?? []
                    
                    // Convert connections
                    let connections = (stepEntity.connections as? Set<NodeConnectionEntity>)?
                        .map { connectionEntity in
                            DSConnection(
                                from: connectionEntity.fromNode?.uuid ?? UUID(),
                                to: connectionEntity.toNode?.uuid ?? UUID(),
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
        
        return VisualizationQuestion(
            title: visualizationEntity.title ?? "",
            description: visualizationEntity.desc ?? "",
            code: codeLines,
            steps: steps,
            initialDSState: [],
            initialConnections: []
        )
    }
    
    // Initialize example visualization for first level's first question
    func initializeExampleVisualization() {
        print("Initializing example visualization...")
        // Check if already initialized
        let fetchRequest: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "level.number == 1 AND type == %@", "visualization")
        
        do {
            let questions = try context.fetch(fetchRequest)
            print("Found \(questions.count) visualization questions for level 1")
            
            if let firstQuestion = questions.first {
                if firstQuestion.visualization == nil {
                    print("Creating visualization for question...")
                    // Create example linked list visualization
                    createVisualization(
                        for: firstQuestion,
                        title: "Building a Linked List",
                        description: "Learn how to build a linked list by following the code and completing the visualization",
                        code: [
                            "class Node {",
                            "    var value: Int",
                            "    var next: Node?",
                            "}",
                            "",
                            "func createList() {",
                            "    let head = Node(5)",
                            "    head.next = Node(3)",
                            "    head.next.next = Node(7)",
                            "}"
                        ],
                        steps: [
                            (1, "First, we define our Node class", [], [], false, []),
                            (7, "Create the head node with value 5",
                             [DSNode(value: "5", position: CGPoint(x: 100, y: 200))],
                             [], false, []),
                            (8, "Add the second node",
                             [
                                DSNode(value: "5", position: CGPoint(x: 100, y: 200)),
                                DSNode(value: "3", position: CGPoint(x: 250, y: 200))
                             ],
                             [
                                DSConnection(
                                    from: UUID(),
                                    to: UUID(),
                                    label: "next"
                                )
                             ],
                             true, ["3", "7", "9"]),
                            (9, "Complete the linked list",
                             [
                                DSNode(value: "5", position: CGPoint(x: 100, y: 200)),
                                DSNode(value: "3", position: CGPoint(x: 250, y: 200)),
                                DSNode(value: "7", position: CGPoint(x: 400, y: 200))
                             ],
                             [
                                DSConnection(
                                    from: UUID(),
                                    to: UUID(),
                                    label: "next"
                                ),
                                DSConnection(
                                    from: UUID(),
                                    to: UUID(),
                                    label: "next"
                                )
                             ],
                             true, ["7"])
                        ]
                    )
                    print("Visualization created successfully")
                } else {
                    print("Visualization already exists for question")
                }
            } else {
                print("No visualization question found for level 1")
            }
        } catch {
            print("Error initializing example visualization: \(error)")
        }
    }
} 