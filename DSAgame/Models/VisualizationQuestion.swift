import SwiftUI

// Represents a single step in the visualization
struct VisualizationStep {
    let id = UUID()
    let codeHighlightedLine: Int
    let lineComment: String?
    let dsState: [DSNode]
    let dsConnections: [DSConnection]
    var userInputRequired: Bool = false
    var availableElements: [String] = []
}

// Represents a visualization question
struct VisualizationQuestion {
    let id = UUID()
    let title: String
    let description: String
    let code: [CodeLine]
    let steps: [VisualizationStep]
    let initialDSState: [DSNode]
    let initialConnections: [DSConnection]
}

// View for draggable elements
struct DraggableElement: View {
    let value: String
    @State private var dragAmount = CGSize.zero
    let onDropped: (String, CGPoint) -> Void
    
    var body: some View {
        Text(value)
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
            .offset(dragAmount)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        dragAmount = gesture.translation
                    }
                    .onEnded { gesture in
                        dragAmount = .zero
                        onDropped(value, gesture.location)
                    }
            )
    }
}

// Main visualization question view
struct VisualizationQuestionView: View {
    let question: VisualizationQuestion
    @State private var currentStepIndex = 0
    @State private var dsNodes: [DSNode]
    @State private var dsConnections: [DSConnection]
    @State private var isAnimating = false
    
    init(question: VisualizationQuestion) {
        self.question = question
        _dsNodes = State(initialValue: question.initialDSState)
        _dsConnections = State(initialValue: question.initialConnections)
    }
    
    var currentStep: VisualizationStep {
        question.steps[currentStepIndex]
    }
    
    func handleElementDrop(_ value: String, at location: CGPoint) {
        // Find the closest node to the drop location
        if let targetNodeIndex = dsNodes.firstIndex(where: { node in
            let distance = sqrt(
                pow(node.position.x - location.x, 2) +
                pow(node.position.y - location.y, 2)
            )
            return distance < 30 // Threshold for dropping
        }) {
            // Update node value
            dsNodes[targetNodeIndex].value = value
            
            // Check if this completes the current step
            if dsNodes == currentStep.dsState {
                moveToNextStep()
            }
        }
    }
    
    func moveToNextStep() {
        guard currentStepIndex < question.steps.count - 1 else { return }
        
        withAnimation {
            currentStepIndex += 1
            if !currentStep.userInputRequired {
                dsNodes = currentStep.dsState
                dsConnections = currentStep.dsConnections
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Title and description
            Text(question.title)
                .font(.title)
                .padding()
            
            Text(question.description)
                .font(.body)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // Code viewer
                CodeViewer(lines: question.code.map { line in
                    var modifiedLine = line
                    modifiedLine.isHighlighted = line.number == currentStep.codeHighlightedLine
                    if line.number == currentStep.codeHighlightedLine {
                        modifiedLine.sideComment = currentStep.lineComment
                    }
                    return modifiedLine
                })
                .frame(width: 400)
                
                // Data structure visualization
                DataStructureView(
                    nodes: dsNodes,
                    connections: dsConnections
                )
                .frame(width: 400, height: 400)
            }
            
            // Available elements for dragging
            if currentStep.userInputRequired {
                HStack(spacing: 15) {
                    ForEach(currentStep.availableElements, id: \.self) { element in
                        DraggableElement(value: element) { value, location in
                            handleElementDrop(value, at: location)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Navigation buttons
            HStack {
                Button(action: {
                    if currentStepIndex > 0 {
                        currentStepIndex -= 1
                        dsNodes = question.steps[currentStepIndex].dsState
                        dsConnections = question.steps[currentStepIndex].dsConnections
                    }
                }) {
                    Text("Previous")
                }
                .disabled(currentStepIndex == 0 || isAnimating)
                
                Spacer()
                
                Button(action: {
                    if !currentStep.userInputRequired {
                        moveToNextStep()
                    }
                }) {
                    Text("Next")
                }
                .disabled(currentStepIndex == question.steps.count - 1 || 
                         currentStep.userInputRequired ||
                         isAnimating)
            }
            .padding()
        }
    }
}

// Example usage
struct VisualizationQuestionExample: View {
    let sampleQuestion = VisualizationQuestion(
        title: "Build a Linked List",
        description: "Watch how a linked list is built step by step and complete the missing values",
        code: [
            CodeLine(
                number: 1,
                content: "func buildList() {",
                syntaxTokens: SyntaxParser.parse("func buildList() {")
            ),
            CodeLine(
                number: 2,
                content: "    let head = Node(1)",
                syntaxTokens: SyntaxParser.parse("    let head = Node(1)")
            ),
            CodeLine(
                number: 3,
                content: "    head.next = Node(2)",
                syntaxTokens: SyntaxParser.parse("    head.next = Node(2)")
            ),
            CodeLine(
                number: 4,
                content: "    head.next.next = Node(3)",
                syntaxTokens: SyntaxParser.parse("    head.next.next = Node(3)")
            )
        ],
        steps: [
            VisualizationStep(
                codeHighlightedLine: 1,
                lineComment: "Starting to build the list",
                dsState: [],
                dsConnections: []
            ),
            VisualizationStep(
                codeHighlightedLine: 2,
                lineComment: "Create the head node",
                dsState: [
                    DSNode(value: "1", position: CGPoint(x: 100, y: 200))
                ],
                dsConnections: []
            ),
            VisualizationStep(
                codeHighlightedLine: 3,
                lineComment: "Add the second node",
                dsState: [
                    DSNode(value: "1", position: CGPoint(x: 100, y: 200)),
                    DSNode(value: "", position: CGPoint(x: 200, y: 200))
                ],
                dsConnections: [
                    DSConnection(
                        from: UUID(), // You'll need to use actual node IDs
                        to: UUID(),
                        label: "next"
                    )
                ],
                userInputRequired: true,
                availableElements: ["2", "3", "4"]
            )
        ],
        initialDSState: [],
        initialConnections: []
    )
    
    var body: some View {
        VisualizationQuestionView(question: sampleQuestion)
    }
}

#Preview {
    VisualizationQuestionExample()
} 
