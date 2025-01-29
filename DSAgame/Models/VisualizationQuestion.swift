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
    let hint: String
    let review: String
    let code: [CodeLine]
    let steps: [VisualizationStep]
    let initialCells: [any DataStructureCell]
    let initialConnections: [any DataStructureConnection]
    let layoutType: DataStructureLayoutType
}

// Add zoom and pan state manager
class VisualizationZoomPanState: ObservableObject {
    @Published var steadyZoom: CGFloat = 1.0
    @Published var steadyPan: CGSize = .zero
}

// Main visualization question view
struct VisualizationQuestionView: View {
    let question: VisualizationQuestion
    let onComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var currentStepIndex = 0
    @State private var currentStep: VisualizationStep
    @State private var visualizationKey = UUID()
    @State private var showingHint = false
    @StateObject private var zoomPanState = VisualizationZoomPanState()
    
    init(question: VisualizationQuestion, onComplete: @escaping () -> Void = {}) {
        print("\n=== Initializing VisualizationQuestionView ===")
        self.question = question
        self.onComplete = onComplete
        _currentStep = State(initialValue: question.steps[0])
        
        print("\nFirst step cells:")
        for (i, cell) in question.steps[0].cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
        
        print("\nInitialization complete")
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Left half - Code viewer
                VStack(spacing: 8) {
                    // Header with close and hint buttons
                    HStack {
                        // Back button
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main Rectangle
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .padding(.leading, 30)
                        .padding(.top, 30)
                        
                        Spacer()
                        
                        // Hint button
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main Rectangle
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            Button(action: {
                                showingHint = true
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .padding(.trailing, 30)
                        .padding(.top, 30)
                    }
                    
                    // Title and description
                    Spacer().frame(height: 30)
                    Text(question.title)
                        .font(.system(.title, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                    Text(question.description)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 5)
                        .padding(.bottom, 20)
                        .padding(.leading, 20)
                    
                    // Code viewer
                    CodeViewer(lines: question.code.map { line in
                        var modifiedLine = line
                        modifiedLine.isHighlighted = line.number == currentStep.codeHighlightedLine
                        modifiedLine.sideComment = line.number == currentStep.codeHighlightedLine ? currentStep.lineComment : nil
                        return modifiedLine
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.leading, 20)
                }
                .frame(maxWidth: .infinity)
                .overlay(
                    Rectangle()
                        .frame(width: 0.5)
                        .foregroundColor(.gray.opacity(0.3)),
                    alignment: .trailing
                )
                .ignoresSafeArea(.container, edges: .leading)
                
                // Right half - Data structure view
                DataStructureView(
                    layoutType: question.layoutType,
                    cells: currentStep.cells,
                    connections: currentStep.connections,
                    availableElements: currentStep.userInputRequired ? currentStep.availableElements : [],
                    onElementDropped: { value, index in
                        if currentStep.userInputRequired {
                            setValue(value, forCellAtIndex: index)
                        }
                    },
                    zoomPanState: zoomPanState
                )
                .id(visualizationKey)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Navigation buttons at the bottom
            VStack {
                Spacer()
                HStack {
                    // This Spacer takes 25% of the space
                    Spacer().frame(width: UIScreen.main.bounds.width * 0.25)
                    
                    // Previous button
                    Button(action: {
                        if currentStepIndex > 0 {
                            let prevIndex = currentStepIndex - 1
                            currentStepIndex = prevIndex
                            currentStep = question.steps[prevIndex]
                            visualizationKey = UUID()
                        }
                    }) {
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main rectangle
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            // Button content
                            Text("Previous")
                                .foregroundColor(currentStepIndex == 0 ? Color.gray : Color.blue)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                        }
                    }
                    .disabled(currentStepIndex == 0)
                    .buttonStyle(.plain)
                    .frame(width: 120, height: 40)
                    .padding(.leading, 40)
                    
                    Spacer()
                    
                    // Next/Complete button
                    Button(action: {
                        if isLastStep {
                            onComplete()
                        } else {
                            moveToNextStep()
                        }
                    }) {
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main rectangle
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            // Button content
                            Text(isLastStep ? "Complete" : "Next")
                                .foregroundColor(!isLastStep && (currentStep.userInputRequired && !isCurrentStepComplete()) ? Color.gray : Color.blue)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                        }
                    }
                    .disabled(!isLastStep && (currentStep.userInputRequired && !isCurrentStepComplete()))
                    .buttonStyle(.plain)
                    .frame(width: 120, height: 40)
                    .padding(.trailing, 40)
                    
                    Spacer()
                }
                .padding()
            }
            
            // Hint overlay
            .overlay(
                Group {
                    if showingHint {
                        ZStack {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    showingHint = false
                                }
                            
                            ZStack {
                                // Shadow layer for the entire box
                                Rectangle()
                                    .fill(Color.black)
                                    .offset(x: 6, y: 6)
                                
                                // Main box
                                Rectangle()
                                    .fill(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                    )
                                
                                VStack(spacing: 20) {
                                    Text("Need a hint?")
                                        .font(.system(.body, design: .monospaced).weight(.bold))
                                    Text(question.hint)
                                        .font(.system(.body, design: .monospaced))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button(action: {
                                        showingHint = false
                                    }) {
                                        ZStack {
                                            // Shadow layer
                                            Rectangle()
                                                .fill(Color.black)
                                                .offset(x: 6, y: 6)
                                            
                                            // Main rectangle
                                            Rectangle()
                                                .fill(Color.white)
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                )
                                            
                                            // Button content
                                            Text("Got it")
                                                .foregroundColor(.blue)
                                                .font(.system(.body, design: .monospaced).weight(.bold))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .frame(width: 120, height: 40)
                                    .padding(.top, 40)
                                }
                                .padding(40)
                                .padding(.top, 20)

                            }
                            .frame(width: 400, height: 300)
                        }
                    }
                }
            )
        }
    }
    
    private var isLastStep: Bool {
        currentStepIndex == question.steps.count - 1
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
        
        // Check if all cells in the current step match the next step's requirements
        return zip(currentStep.cells, nextStep.cells).allSatisfy { current, next in
            // If next cell is empty, current cell should also be empty
            if next.value.isEmpty {
                return current.value.isEmpty
            }
            // If next cell has a value, current cell must match exactly
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
        hint: "Start by creating the head node, then connect each new node to the previous one.",
        review: "Great job! You've learned how to build a linked list by connecting nodes in sequence. Each node points to the next one, forming a chain of data.",
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
