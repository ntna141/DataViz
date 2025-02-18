import Foundation
import SwiftUI

// Represents a single step in the visualization
struct VisualizationStep {
    let id = UUID()
    let codeHighlightedLine: Int
    let lineComment: String?
    let hint: String?
    var cells: [any DataStructureCell]
    var connections: [any DataStructureConnection]
    var userInputRequired: Bool = false
    var availableElements: [String]? = nil
    var isMultipleChoice: Bool = false
    var multipleChoiceAnswers: [String] = []
    var multipleChoiceCorrectAnswer: String = ""
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

// Add this before VisualizationQuestionView
class VisualizationCompletionManager: ObservableObject {
    private var completedSteps: Set<UUID> = []
    private var stepAnswers: [UUID: String] = [:]
    private var stepCells: [UUID: [any DataStructureCell]] = [:]
    
    func markStepCompleted(_ step: VisualizationStep, answer: String? = nil, cells: [any DataStructureCell]? = nil) {
        completedSteps.insert(step.id)
        if let answer = answer {
            stepAnswers[step.id] = answer
        }
        if let cells = cells {
            stepCells[step.id] = cells
        }
    }
    
    func isStepCompleted(_ step: VisualizationStep) -> Bool {
        return completedSteps.contains(step.id)
    }
    
    func getStoredAnswer(_ step: VisualizationStep) -> String? {
        return stepAnswers[step.id]
    }
    
    func getStoredCells(_ step: VisualizationStep) -> [any DataStructureCell]? {
        return stepCells[step.id]
    }
    
    private var currentStepIndex: Int = 0
    
    func updateCurrentStepIndex(_ index: Int) {
        currentStepIndex = index
    }
}

// Main visualization question view
struct VisualizationQuestionView: View {
    let question: VisualizationQuestion
    let questionId: String
    let onComplete: () -> Void
    let isCompleted: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var currentStepIndex = 0 {
        didSet {
            completionManager.updateCurrentStepIndex(currentStepIndex)
        }
    }
    @State private var steps: [VisualizationStep]  // Store all steps to maintain their state
    @State private var visualizationKey = UUID()
    @State private var showingHint = false
    @State private var selectedAnswer: String = ""
    @StateObject private var completionManager = VisualizationCompletionManager()
    @State private var isAutoPlaying = false
    @State private var autoPlayTimer: Timer?
    @StateObject private var cellSizeManager = CellSizeManager()
    @StateObject private var elementListState = ElementListState()
    
    init(question: VisualizationQuestion, questionId: String, onComplete: @escaping () -> Void = {}, isCompleted: Bool = false) {
        self.question = question
        self.questionId = questionId
        self.onComplete = onComplete
        self.isCompleted = isCompleted
        _steps = State(initialValue: question.steps)  // Initialize steps array
        
        let firstStep = question.steps[0]
        if firstStep.isMultipleChoice {
            print("Multiple choice answers: \(firstStep.multipleChoiceAnswers)")
            print("Correct answer: \(firstStep.multipleChoiceCorrectAnswer)")
        }
    }
    
    private var currentStep: VisualizationStep {
        let step = steps[currentStepIndex]
        if let answer = completionManager.getStoredAnswer(step) {
            print("Stored Answer: \(answer)")
        }
        return step
    }
    
    private func updateCurrentStep(_ step: VisualizationStep) {
        steps[currentStepIndex] = step
        visualizationKey = UUID()
    }
    
    private var isCurrentStepCompleted: Bool {
        let step = currentStep
        
        // For multiple choice questions
        if step.isMultipleChoice {
            // If already completed, return true
            if completionManager.isStepCompleted(step) {
                return true
            }
            
            // Check if current answer is correct
            return selectedAnswer == step.multipleChoiceCorrectAnswer
        }
        
        // For user input questions
        if step.userInputRequired {
            // If already completed, return true
            if completionManager.isStepCompleted(step) {
                return true
            }
            
            // Check if current state matches next step
            guard let nextStep = steps[safe: currentStepIndex + 1] else { return false }
            return zip(step.cells, nextStep.cells).allSatisfy { current, next in
                if next.value.isEmpty {
                    return current.value.isEmpty
                }
                return current.value == next.value
            }
        }
        
        // For non-interactive steps, mark as completed when visited
        if !completionManager.isStepCompleted(step) {
            completionManager.markStepCompleted(step)
        }
        return true
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Left half - Code viewer
                VStack(spacing: 8) {
                    // Title
                    Text(question.title)
                        .font(.system(.title, design: .monospaced))
                        .padding(.top, 30)
                        .frame(maxWidth: .infinity * 0.95, alignment: .leading)
                        .padding(.leading, 16)
                    
                    // Back button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        buttonBackground {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                Text("Back")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.blue)
                            .font(.body)
                        }
                    }
                    .frame(width: 80, height: 32)
                    .padding(.leading, 16)
                    .padding(.vertical, 12)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Code viewer
                    CodeViewer(lines: question.code.map { line in
                        var modifiedLine = line
                        modifiedLine.isHighlighted = line.number == currentStep.codeHighlightedLine
                        modifiedLine.sideComment = line.number == currentStep.codeHighlightedLine ? currentStep.lineComment : nil
                        return modifiedLine
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
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
                    availableElements: currentStep.availableElements,
                    onElementDropped: { value, index in
                        if currentStep.userInputRequired && !isCurrentStepCompleted {
                            setValue(value, forCellAtIndex: index)
                        }
                    },
                    isAutoPlaying: isAutoPlaying,
                    onPlayPausePressed: {
                        if isAutoPlaying {
                            stopAutoPlay()
                        } else {
                            startAutoPlay()
                        }
                    },
                    autoPlayInterval: calculateAutoPlayInterval(comment: currentStep.lineComment),
                    hint: currentStep.hint,
                    lineComment: currentStep.lineComment,
                    isMultipleChoice: currentStep.isMultipleChoice,
                    multipleChoiceAnswers: currentStep.multipleChoiceAnswers,
                    onMultipleChoiceAnswerSelected: { answer in
                        if !isCurrentStepCompleted {
                            print("\nMultiple choice answer selected: \(answer)")
                            selectedAnswer = answer
                            print("Updated selectedAnswer to: \(selectedAnswer)")
                        }
                    },
                    selectedMultipleChoiceAnswer: selectedAnswer,
                    onShowAnswer: showAnswer,
                    isCompleted: completionManager.isStepCompleted(currentStep) && (currentStep.isMultipleChoice || currentStep.userInputRequired),
                    questionId: questionId,
                    elementListState: elementListState
                )
                .id(visualizationKey)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    if isCompleted {
                        let step = currentStep
                        if step.isMultipleChoice {
                            completionManager.markStepCompleted(step, answer: step.multipleChoiceCorrectAnswer)
                        } else if step.userInputRequired {
                            if let nextStep = steps[safe: currentStepIndex + 1] {
                                completionManager.markStepCompleted(step, cells: nextStep.cells)
                            }
                        } else {
                            completionManager.markStepCompleted(step)
                        }
                    }
                }
                .onChange(of: currentStep.availableElements) { newElements in
                    elementListState.hardReset(with: newElements)
                }
            }
            
            // Hint overlay
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
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                                Text("Hint")
                                    .font(.system(.title2, design: .monospaced).weight(.bold))
                            }
                            
                            Text(currentStep.hint ?? "")
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showingHint = false
                            }) {
                                buttonBackground {
                                    Text("Got it!")
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
            
            // Add navigation buttons at the bottom
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
                            selectedAnswer = ""  // Always reset selected answer when navigating
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
                        if shouldDisableNextButton {
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
                            Text(shouldShowComplete ? "Complete" : "Next")
                                .foregroundColor(shouldDisableNextButton ? Color.gray : Color.blue)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                        }
                    }
                    .disabled(shouldDisableNextButton)
                    .buttonStyle(.plain)
                    .frame(width: 120, height: 40)
                    .padding(.trailing, 40)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onChange(of: question.layoutType) { newType in
            handleLayoutTypeChange(newType)
        }
        .environmentObject(cellSizeManager)
        .onDisappear {
            stopAutoPlay()
        }
    }
    
    private var isLastStep: Bool {
        currentStepIndex == question.steps.count - 1
    }
    
    private var shouldDisableNextButton: Bool {
        // If the question is already completed, allow moving forward
        if isCompleted {
            return false
        }
        
        // If the current step requires input or is multiple choice, check completion
        if currentStep.userInputRequired || currentStep.isMultipleChoice {
            return !isCurrentStepCompleted
        }
        
        // For non-interactive steps, always allow moving forward
        return false
    }
    
    private var shouldShowComplete: Bool {
        // Show Complete if we're on the last step and either:
        // 1. The question is already completed, or
        // 2. The current step is completed (for interactive steps)
        // 3. The current step doesn't require interaction
        isLastStep && (
            isCompleted ||
            isCurrentStepCompleted ||
            (!currentStep.userInputRequired && !currentStep.isMultipleChoice)
        )
    }
    
    private var shouldShowAnswerButton: Bool {
        // Only show answer button if:
        // 1. The question is completed AND
        // 2. The current step is interactive (multiple choice or user input)
        isCompleted && (currentStep.isMultipleChoice || currentStep.userInputRequired)
    }
    
    private func moveToNextStep() {
        // If we're at the last step and it's completed, call onComplete
        if isLastStep && (isCompleted || isCurrentStepCompleted) {
            onComplete()
            return
        }
        
        // Only move to next step if current step is completed or question is completed
        if !isCompleted && !isCurrentStepCompleted {
            return
        }
        
        // Mark current step as completed and store the answer/cells
        let step = currentStep
        if !completionManager.isStepCompleted(step) {
            if step.isMultipleChoice {
                completionManager.markStepCompleted(step, answer: selectedAnswer)
            } else if step.userInputRequired {
                completionManager.markStepCompleted(step, cells: step.cells)
            } else {
                completionManager.markStepCompleted(step)
            }
        }
        
        let nextIndex = currentStepIndex + 1
        guard nextIndex < steps.count else { return }
        
        // Reset state before moving to next step
        selectedAnswer = ""  // Reset selected answer when navigating
        visualizationKey = UUID()  // Force a refresh of the visualization
        
        // Update the current step index last to trigger the state update
        currentStepIndex = nextIndex
        
        // If the question is completed, mark the next step as completed too
        if isCompleted {
            let nextStep = steps[nextIndex]
            if nextStep.isMultipleChoice {
                completionManager.markStepCompleted(nextStep, answer: nextStep.multipleChoiceCorrectAnswer)
            } else if nextStep.userInputRequired {
                if let followingStep = steps[safe: nextIndex + 1] {
                    completionManager.markStepCompleted(nextStep, cells: followingStep.cells)
                }
            } else {
                completionManager.markStepCompleted(nextStep)
            }
        }
    }
    
    private func showAnswer() {
        let step = currentStep
        if step.isMultipleChoice {
            if let storedAnswer = completionManager.getStoredAnswer(step) {
                selectedAnswer = storedAnswer
            } else {
                selectedAnswer = step.multipleChoiceCorrectAnswer
            }
        } else if step.userInputRequired {
            if let storedCells = completionManager.getStoredCells(step) {
                var updatedStep = step
                updatedStep.cells = storedCells
                steps[currentStepIndex] = updatedStep
            } else if let nextStep = steps[safe: currentStepIndex + 1] {
                var updatedStep = step
                updatedStep.cells = nextStep.cells
                steps[currentStepIndex] = updatedStep
                completionManager.markStepCompleted(step, cells: nextStep.cells)
            }
        }
        visualizationKey = UUID()
    }
    
    private func setValue(_ value: String, forCellAtIndex index: Int) {
        guard index < currentStep.cells.count else { return }
        var updatedStep = steps[currentStepIndex]
        var newCells = updatedStep.cells
        var updatedCell = newCells[index]
        updatedCell.setValue(value)
        newCells[index] = updatedCell
        updatedStep.cells = newCells
        steps[currentStepIndex] = updatedStep
        visualizationKey = UUID()
    }
    
    private func buttonBackground<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
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
            
            content()
        }
    }
    
    private func startAutoPlay() {
        guard !isLastStep && !currentStep.userInputRequired else {
            isAutoPlaying = false
            return
        }
        
        isAutoPlaying = true
        scheduleNextStep()
    }
    
    private func stopAutoPlay() {
        isAutoPlaying = false
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    private func scheduleNextStep() {
        // Cancel any existing timer
        autoPlayTimer?.invalidate()
        
        // Calculate interval based on current step's comment
        let interval = calculateAutoPlayInterval(comment: currentStep.lineComment)
        
        // Schedule next step
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [self] _ in
            if isAutoPlaying && !isLastStep && !currentStep.userInputRequired {
                moveToNextStep()
                // If we can continue, schedule the next step
                if !isLastStep && !currentStep.userInputRequired {
                    scheduleNextStep()
                } else {
                    stopAutoPlay()
                }
            } else {
                stopAutoPlay()
            }
        }
    }
    
    private func handleLayoutTypeChange(_ newType: DataStructureLayoutType) {
        // Implementation of handleLayoutTypeChange method
    }
    
    private func calculateAutoPlayInterval(comment: String?) -> TimeInterval {
        guard let comment = comment else { return 3.0 }  // Default interval if no comment
        
        // Base interval of 2 seconds
        let baseInterval: TimeInterval = 2.0
        
        // Add 0.05 seconds per character (about 20 chars per second reading speed)
        let additionalTime = TimeInterval(comment.count) * 0.05
        
        // Clamp the total interval between 2 and 7 seconds
        return min(max(baseInterval + additionalTime, 2.0), 7.0)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
