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
    @State private var position = CGPoint.zero
    @State private var isDragging = false
    let onDropped: (String, CGPoint) -> Void
    
    var body: some View {
        Text(value)
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: isDragging ? 4 : 2)
            .position(x: position.x, y: position.y)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        position = gesture.location
                    }
                    .onEnded { gesture in
                        isDragging = false
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
    @State private var visualizationArea: CGRect = .zero
    @State private var visualizationFrame: CGRect = .zero
    
    init(question: VisualizationQuestion) {
        self.question = question
        _dsNodes = State(initialValue: question.initialDSState)
        _dsConnections = State(initialValue: question.initialConnections)
    }
    
    var currentStep: VisualizationStep {
        question.steps[currentStepIndex]
    }
    
    func updateNodePositions() {
        guard !visualizationFrame.isEmpty else { return }
        dsNodes = DataStructureLayoutManager.calculateLinkedListLayout(nodes: dsNodes, in: visualizationFrame)
    }
    
    func handleElementDrop(_ value: String, at location: CGPoint) {
        // Convert the screen coordinates to visualization area coordinates
        let visualizationLocation = CGPoint(
            x: location.x - visualizationArea.minX,
            y: location.y - visualizationArea.minY
        )
        
        // Check if the drop is within the visualization area
        guard visualizationArea.contains(location) else { return }
        
        // Find the closest empty node to the drop location
        if let targetNodeIndex = dsNodes.firstIndex(where: { node in
            let distance = sqrt(
                pow(node.position.x - visualizationLocation.x, 2) +
                pow(node.position.y - visualizationLocation.y, 2)
            )
            return distance < DataStructureLayoutManager.nodeRadius && node.value.isEmpty // Only allow dropping on empty nodes
        }) {
            // Update node value
            var updatedNodes = dsNodes
            updatedNodes[targetNodeIndex].value = value
            dsNodes = updatedNodes
            
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
                updateNodePositions()
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
                ZStack {
                    Color.white
                        .shadow(radius: 2)
                        .preference(key: FramePreferenceKey.self, value: geometry.frame(in: .local))
                    
                    // Data structure visualization
                    DataStructureView(
                        nodes: dsNodes,
                        connections: dsConnections,
                        layoutType: question.layoutType
                    )
                    .padding()
                    
                    // Available elements for dragging
                    if currentStep.userInputRequired {
                        VStack {
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
                            
                            Spacer()
                        }
                        .padding(.top)
                    }
                }
                .frame(height: geometry.size.height * 0.4)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            visualizationArea = geo.frame(in: .global)
                        }
                    }
                )
                .onPreferenceChange(FramePreferenceKey.self) { frame in
                    visualizationFrame = frame
                    updateNodePositions()
                }
                
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
                
                // Fixed navigation bar at the bottom
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
            .onAppear {
                updateNodePositions()
            }
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
