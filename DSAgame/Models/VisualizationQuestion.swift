import SwiftUI

// Represents a single step in the visualization
struct VisualizationStep {
    let id = UUID()
    let codeHighlightedLine: Int
    let lineComment: String?
    var cells: [any DataStructureCell]
    var connections: [any DataStructureConnection]
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
    let initialCells: [any DataStructureCell]
    let initialConnections: [any DataStructureConnection]
    let layoutType: DataStructureLayoutType
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
    @State private var currentStep: VisualizationStep
    @State private var visualizationKey = UUID()
    
    init(question: VisualizationQuestion) {
        print("\n=== Initializing VisualizationQuestionView ===")
        self.question = question
        _currentStep = State(initialValue: question.steps[0])
        
        print("\nFirst step cells:")
        for (i, cell) in question.steps[0].cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
        
        print("\nInitialization complete")
    }
    
    var body: some View {
        VStack {
            // Title and description
            Text(question.title).font(.title)
            Text(question.description).font(.body)
            
            // Code viewer
            CodeViewer(lines: question.code.map { line in
                var modifiedLine = line
                modifiedLine.isHighlighted = line.number == currentStep.codeHighlightedLine
                modifiedLine.sideComment = line.number == currentStep.codeHighlightedLine ? currentStep.lineComment : nil
                return modifiedLine
            })
            
            // Data structure view with key for complete re-render
            ZStack {
                DataStructureView(
                    layoutType: question.layoutType,
                    cells: currentStep.cells,
                    connections: currentStep.connections,
                    availableElements: [],  // Don't pass available elements here
                    onElementDropped: { value, index in
                        if currentStep.userInputRequired {
                            setValue(value, forCellAtIndex: index)
                            // Check against next step for validation
                            if let nextStep = question.steps[safe: currentStepIndex + 1],
                               currentStep.cells[index].value == nextStep.cells[index].value {
                                moveToNextStep()
                            }
                        }
                    }
                )
                .id(visualizationKey)
            }
            .coordinateSpace(name: "dataStructureSpace")
            
            // Available elements for dragging (only show if user input required)
            if currentStep.userInputRequired && !currentStep.availableElements.isEmpty {
                HStack {
                    ForEach(currentStep.availableElements, id: \.self) { element in
                        DraggableElement(value: element) { value, location in
                            // Find the closest cell and update its value
                            if let index = findClosestCell(to: location) {
                                setValue(value, forCellAtIndex: index)
                                // Check against next step for validation
                                if let nextStep = question.steps[safe: currentStepIndex + 1],
                                   currentStep.cells[index].value == nextStep.cells[index].value {
                                    moveToNextStep()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Navigation
            HStack {
                Button("Previous") {
                    if currentStepIndex > 0 {
                        let prevIndex = currentStepIndex - 1
                        currentStepIndex = prevIndex
                        currentStep = question.steps[prevIndex]
                        visualizationKey = UUID()
                    }
                }
                .disabled(currentStepIndex == 0)
                
                Spacer()
                
                Button("Next") {
                    if !currentStep.userInputRequired {
                        moveToNextStep()
                    }
                }
                .disabled(currentStep.userInputRequired || currentStepIndex == question.steps.count - 1)
            }
            .padding()
        }
    }
    
    private func moveToNextStep() {
        print("\n=== Moving to Next Step ===")
        
        let nextIndex = currentStepIndex + 1
        guard nextIndex < question.steps.count else { return }
        
        let nextStep = question.steps[nextIndex]
        
        print("\nCurrent step cells:")
        for (i, cell) in currentStep.cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
        
        print("\nNext step cells:")
        for (i, cell) in nextStep.cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
        
        currentStepIndex = nextIndex
        currentStep = nextStep
        visualizationKey = UUID()
        
        print("\nMoved to step \(nextIndex)")
        print("Updated cells:")
        for (i, cell) in currentStep.cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
    }
    
    private func setValue(_ value: String, forCellAtIndex index: Int) {
        guard index < currentStep.cells.count else { return }
        var newCells = currentStep.cells
        var updatedCell = newCells[index]
        updatedCell.setValue(value)
        newCells[index] = updatedCell
        currentStep.cells = newCells
        visualizationKey = UUID()
    }
    
    private func findClosestCell(to point: CGPoint) -> Int? {
        // For now, just return index 1 since that's where we want to place the value
        // In a real implementation, you would calculate distances to each cell
        return 1
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
                cells: [],
                connections: []
            ),
            VisualizationStep(
                codeHighlightedLine: 2,
                lineComment: "Create the head node",
                cells: [
                    BasicCell(value: "1")
                ],
                connections: []
            ),
            VisualizationStep(
                codeHighlightedLine: 3,
                lineComment: "Add the second node",
                cells: [
                    BasicCell(id: "node1", value: "1"),
                    BasicCell(id: "node2", value: "")
                ],
                connections: [
                    BasicConnection(
                        fromCellId: "node1",
                        toCellId: "node2",
                        label: "next"
                    )
                ],
                userInputRequired: true,
                availableElements: ["2", "3", "4"]
            )
        ],
        initialCells: [],
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
