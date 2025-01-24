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
        VStack(spacing: 10) {
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
            .frame(maxHeight: 240)  // Increased by 20%
            .overlay(
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.gray.opacity(0.3))
                    Spacer()
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.gray.opacity(0.3))
                }
            )
            
            // Data structure view with key for complete re-render
            DataStructureView(
                layoutType: question.layoutType,
                cells: currentStep.cells,
                connections: currentStep.connections,
                availableElements: currentStep.userInputRequired ? currentStep.availableElements : [],
                onElementDropped: { value, index in
                    if currentStep.userInputRequired {
                        setValue(value, forCellAtIndex: index)
                    }
                }
            )
            .id(visualizationKey)
            .frame(maxHeight: .infinity)  // Take up remaining space
            
            Spacer()  // Flexible space to push buttons to bottom
            
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
                    moveToNextStep()
                }
                .disabled(currentStepIndex == question.steps.count - 1 || 
                         (currentStep.userInputRequired && !isCurrentStepComplete()))
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
    
    private func isCurrentStepComplete() -> Bool {
        guard let nextStep = question.steps[safe: currentStepIndex + 1] else { return false }
        // Check if all non-empty cells in the next step have matching values in current step
        return zip(currentStep.cells, nextStep.cells).allSatisfy { current, next in
            if next.value.isEmpty {
                return true // Skip validation for empty cells in next step
            }
            return current.value == next.value
        }
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
