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
    let layoutType: DataStructureView.LayoutType
}

// View for draggable elements
struct DraggableElement: View {
    let value: String
    @State private var isDragging = false
    @State private var dragLocation: CGPoint = .zero
    let onDropped: (String, CGPoint) -> Void
    
    var body: some View {
        Text(value)
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: isDragging ? 4 : 2)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(isDragging ? 0.7 : 1.0)
            .overlay(
                GeometryReader { geometry in
                    if isDragging {
                        Text(value)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .position(dragLocation)
                    }
                }
            )
            .gesture(
                DragGesture(coordinateSpace: .named("dataStructureSpace"))
                    .onChanged { gesture in
                        isDragging = true
                        dragLocation = gesture.location
                    }
                    .onEnded { gesture in
                        isDragging = false
                        onDropped(value, gesture.location)
                    }
            )
            .animation(.spring(response: 0.3), value: isDragging)
    }
}

// Represents a dragging state
struct DragState {
    var value: String
    var position: CGPoint
    var isDragging: Bool
}

// Main visualization question view
struct VisualizationQuestionView: View {
    let question: VisualizationQuestion
    @State private var currentStepIndex = 0
    @State private var dsNodes: [DSNode]
    @State private var dsConnections: [DSConnection]
    @State private var isAnimating = false
    @State private var targetNodeIndex: Int?
    
    init(question: VisualizationQuestion) {
        self.question = question
        _dsNodes = State(initialValue: question.initialDSState)
        _dsConnections = State(initialValue: question.initialConnections)
    }
    
    var currentStep: VisualizationStep {
        question.steps[currentStepIndex]
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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Title and description
                Text(question.title)
                    .font(.title)
                    .padding(.top)
                
                Text(question.description)
                    .font(.body)
                    .padding(.horizontal)
                
                // Visualization area with draggable elements and data structure
                GeometryReader { visualizationGeometry in
                    ZStack(alignment: .top) {
                        // Data structure visualization
                        DataStructureView(
                            nodes: dsNodes,
                            connections: dsConnections,
                            layoutType: question.layoutType,
                            targetNodeIndex: targetNodeIndex
                        )
                        .onChange(of: dsNodes) { newNodes in
                            print("\n=== Node State Update ===")
                            for (index, node) in newNodes.enumerated() {
                                print("Node \(index):")
                                print("  - Position: \(node.position)")
                                print("  - Value: '\(node.value)'")
                                print("  - Empty: \(node.value.isEmpty)")
                            }
                        }
                        
                        // Available elements for dragging
                        if currentStep.userInputRequired {
                            HStack(spacing: 15) {
                                ForEach(currentStep.availableElements, id: \.self) { element in
                                    DraggableElement(value: element) { value, dropLocation in
                                        print("\n=== Drop Event ===")
                                        print("Drop location: \(dropLocation)")
                                        print("Current nodes state:")
                                        
                                        var closestDistance = CGFloat.infinity
                                        var closestNodeIndex: Int?
                                        
                                        for (index, node) in dsNodes.enumerated() {
                                            // Use node position directly since we're in the same coordinate space
                                            let distance = sqrt(
                                                pow(node.position.x - dropLocation.x, 2) +
                                                pow(node.position.y - dropLocation.y, 2)
                                            )
                                            
                                            print("Node \(index):")
                                            print("  - Position: \(node.position)")
                                            print("  - Value: '\(node.value)'")
                                            print("  - Distance to drop: \(distance)")
                                            
                                            // Update closest node if this is closer and empty
                                            if distance < closestDistance && node.value.isEmpty {
                                                closestDistance = distance
                                                closestNodeIndex = index
                                            }
                                        }
                                        
                                        print("Closest empty node index: \(String(describing: closestNodeIndex))")
                                        print("Closest distance: \(closestDistance)")
                                        
                                        // Only update if within a reasonable distance (e.g., 100 points)
                                        if let targetIndex = closestNodeIndex, closestDistance < 100 {
                                            print("Updating node at index: \(targetIndex) with value: \(value)")
                                            
                                            // Update node value
                                            var updatedNodes = dsNodes
                                            updatedNodes[targetIndex].value = value
                                            dsNodes = updatedNodes
                                            
                                            // Check if this completes the current step
                                            let isComplete = dsNodes.count == currentStep.dsState.count &&
                                                zip(dsNodes, currentStep.dsState).allSatisfy { currentNode, expectedNode in
                                                    currentNode.value == expectedNode.value
                                                }
                                            
                                            print("Step complete: \(isComplete)")
                                            
                                            if isComplete {
                                                moveToNextStep()
                                            }
                                        } else {
                                            print("Drop rejected - too far from any empty node")
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.top)
                        }
                    }
                }
                .frame(height: geometry.size.height * 0.4)
                .coordinateSpace(name: "dataStructureSpace")
                
                // Code viewer in scrollview
                ScrollView {
                    CodeViewer(lines: question.code.map { line in
                        var modifiedLine = line
                        modifiedLine.isHighlighted = line.number == currentStep.codeHighlightedLine
                        if line.number == currentStep.codeHighlightedLine {
                            modifiedLine.sideComment = currentStep.lineComment
                        }
                        return modifiedLine
                    })
                    .frame(minHeight: geometry.size.height * 0.35)
                }
                .padding(.horizontal)
                
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
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120)
                            .background(currentStepIndex > 0 ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(currentStepIndex == 0 || isAnimating)
                    
                    Spacer()
                    
                    Button(action: {
                        if !currentStep.userInputRequired {
                            moveToNextStep()
                        }
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120)
                            .background(
                                (!currentStep.userInputRequired && currentStepIndex < question.steps.count - 1) 
                                ? Color.blue : Color.gray
                            )
                            .cornerRadius(10)
                    }
                    .disabled(currentStepIndex == question.steps.count - 1 || 
                             currentStep.userInputRequired ||
                             isAnimating)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    Color(.systemBackground)
                        .shadow(radius: 2, y: -2)
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
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
                    DSNode(value: "1")
                ],
                dsConnections: []
            ),
            VisualizationStep(
                codeHighlightedLine: 3,
                lineComment: "Add the second node",
                dsState: [
                    DSNode(value: "1"),
                    DSNode(value: "")
                ],
                dsConnections: [
                    DSConnection(
                        from: UUID(),
                        to: UUID(),
                        label: "next"
                    )
                ],
                userInputRequired: true,
                availableElements: ["2", "3", "4"]
            )
        ],
        initialDSState: [],
        initialConnections: [],
        layoutType: .linkedList
    )
    
    var body: some View {
        VisualizationQuestionView(question: sampleQuestion)
    }
}

#Preview {
    VisualizationQuestionExample()
} 
