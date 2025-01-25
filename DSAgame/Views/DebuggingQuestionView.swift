import SwiftUI

struct DebuggingQuestionView: View {
    let question: VisualizationQuestion
    @State private var currentStepIndex = 0
    @State private var selectedLines = Set<Int>()
    @Environment(\.presentationMode) var presentationMode
    
    private var currentStep: VisualizationStep {
        question.steps[currentStepIndex]
    }
    
    init(question: VisualizationQuestion) {
        self.question = question
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Header with close button
            HStack {
                Text(question.title)
                    .font(.title)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            Text(question.description)
                .font(.body)
                .padding(.horizontal)
            
            // Code viewer with selection
            DebugCodeViewer(
                lines: question.code.map { line in
                    var modifiedLine = line
                    modifiedLine.isHighlighted = line.number == currentStep.codeHighlightedLine
                    modifiedLine.sideComment = line.number == currentStep.codeHighlightedLine ? currentStep.lineComment : nil
                    return modifiedLine
                },
                selectedLines: $selectedLines
            )
            .frame(maxHeight: 240)
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
            
            // Data structure visualization
            DataStructureView(
                layoutType: question.layoutType,
                cells: currentStep.cells,
                connections: currentStep.connections,
                availableElements: currentStep.availableElements,
                onElementDropped: { _, _ in }
            )
            .id(currentStepIndex)
            .frame(maxHeight: .infinity)
            
            // Navigation and submit buttons
            HStack {
                Button("Previous") {
                    if currentStepIndex > 0 {
                        moveToStep(currentStepIndex - 1)
                    }
                }
                .disabled(currentStepIndex == 0)
                
                Spacer()
                
                if currentStep.userInputRequired {
                    Button("Submit") {
                        checkAnswer()
                    }
                    .disabled(selectedLines.isEmpty)
                } else {
                    Button("Next") {
                        moveToNextStep()
                    }
                    .disabled(currentStepIndex == question.steps.count - 1)
                }
            }
            .padding()
        }
    }
    
    private func moveToStep(_ index: Int) {
        guard index >= 0 && index < question.steps.count else { return }
        currentStepIndex = index
        
        // Clear selection when moving to a new step
        if !currentStep.userInputRequired {
            selectedLines.removeAll()
        }
    }
    
    private func moveToNextStep() {
        moveToStep(currentStepIndex + 1)
    }
    
    private func checkAnswer() {
        guard let correctLines = currentStep.correctLines else { return }
        
        if Set(correctLines) == selectedLines {
            // Move to next sequence of frames showing correct behavior
            moveToNextStep()
        } else {
            // Provide feedback (you can customize this)
            // For now, just clear the selection
            selectedLines.removeAll()
        }
    }
}

#Preview {
    // Create a sample debugging question for preview
    let sampleQuestion = VisualizationQuestion(
        title: "Debug the Linked List",
        description: "Find the bug in this linked list implementation",
        code: [
            CodeLine(number: 1, content: "func createList() {", syntaxTokens: SyntaxParser.parse("func createList() {")),
            CodeLine(number: 2, content: "    let head = Node(5)", syntaxTokens: SyntaxParser.parse("    let head = Node(5)")),
            CodeLine(number: 3, content: "    head.next = Node(3)", syntaxTokens: SyntaxParser.parse("    head.next = Node(3)")),
            CodeLine(number: 4, content: "    head.next = Node(7)", syntaxTokens: SyntaxParser.parse("    head.next = Node(7)"))  // Bug: overwrites previous next
        ],
        steps: [
            VisualizationStep(
                codeHighlightedLine: 1,
                lineComment: "Let's see what happens with this code",
                cells: [],
                connections: [],
                userInputRequired: true,
                availableElements: [],
                frameIndex: 0,
                correctLines: [4]  // Line 4 contains the bug
            )
        ],
        initialCells: [],
        initialConnections: [],
        layoutType: .linkedList,
        type: "debugging"  // Specify that this is a debugging question
    )
    
    return DebuggingQuestionView(question: sampleQuestion)
} 
