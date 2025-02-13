import Foundation
import CoreData
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

// Add zoom and pan state manager
class VisualizationZoomPanState: ObservableObject {
    @Published var steadyZoom: CGFloat = 1.0
    @Published var steadyPan: CGSize = .zero
}

// Add this before VisualizationQuestionView
class VisualizationCompletionManager: ObservableObject {
    private let context: NSManagedObjectContext
    private var stepEntities: [Int: VisualizationStepEntity] = [:]
    
    init(questionEntity: QuestionEntity) {
        self.context = PersistenceController.shared.container.viewContext
        if let visualization = questionEntity.visualization,
           let steps = visualization.steps as? Set<VisualizationStepEntity> {
            // Create a mapping of step indices to their entities
            for step in steps {
                stepEntities[Int(step.orderIndex)] = step
            }
        }
    }
    
    func markStepCompleted(_ step: VisualizationStep, answer: String? = nil, cells: [any DataStructureCell]? = nil) {
        guard let stepEntity = stepEntities[currentStepIndex] else { return }
        
        stepEntity.isCompleted = true
        if let answer = answer {
            stepEntity.multipleChoiceCorrectAnswer = answer
        }
        
        // Save the context
        do {
            try context.save()
            print("Marked step \(currentStepIndex) as completed")
        } catch {
            print("Error saving completion state: \(error)")
        }
    }
    
    func isStepCompleted(_ step: VisualizationStep) -> Bool {
        guard let stepEntity = stepEntities[currentStepIndex] else { return false }
        return stepEntity.isCompleted
    }
    
    func getStoredAnswer(_ step: VisualizationStep) -> String? {
        guard let stepEntity = stepEntities[currentStepIndex] else { return nil }
        return stepEntity.multipleChoiceCorrectAnswer
    }
    
    func getStoredCells(_ step: VisualizationStep) -> [any DataStructureCell]? {
        return nil
    }
    
    private var currentStepIndex: Int = 0
    
    func updateCurrentStepIndex(_ index: Int) {
        currentStepIndex = index
        print("Updated current step index to: \(index)")
    }
}

// Main visualization question view
struct VisualizationQuestionView: View {
    let question: VisualizationQuestion
    let questionEntity: QuestionEntity
    let onComplete: () -> Void
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
    @StateObject private var zoomPanState = VisualizationZoomPanState()
    @StateObject private var completionManager: VisualizationCompletionManager
    @State private var isAutoPlaying = false
    @State private var autoPlayTimer: Timer?
    @StateObject private var cellSizeManager = CellSizeManager()
    
    init(question: VisualizationQuestion, questionEntity: QuestionEntity, onComplete: @escaping () -> Void = {}) {
        self.question = question
        self.questionEntity = questionEntity
        self.onComplete = onComplete
        _steps = State(initialValue: question.steps)  // Initialize steps array
        _completionManager = StateObject(wrappedValue: VisualizationCompletionManager(questionEntity: questionEntity))
        
        let firstStep = question.steps[0]
        if firstStep.isMultipleChoice {
            print("Multiple choice answers: \(firstStep.multipleChoiceAnswers)")
            print("Correct answer: \(firstStep.multipleChoiceCorrectAnswer)")
        }
        
    }
    
    private var currentStep: VisualizationStep {
        let step = steps[currentStepIndex]
        print("\n=== Current Step Status ===")
        print("Step Index: \(currentStepIndex)")
        print("Step Completion Status: \(completionManager.isStepCompleted(step))")
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
        if completionManager.isStepCompleted(step) {
            return true
        }
        
        if step.isMultipleChoice {
            let isCorrect = selectedAnswer == step.multipleChoiceCorrectAnswer
            if isCorrect {
                completionManager.markStepCompleted(step, answer: selectedAnswer)
            }
            return isCorrect
        }
        
        if step.userInputRequired {
            guard let nextStep = steps[safe: currentStepIndex + 1] else { return false }
            
            let isCorrect = zip(step.cells, nextStep.cells).allSatisfy { current, next in
                if next.value.isEmpty {
                    return current.value.isEmpty
                }
                return current.value == next.value
            }
            
            if isCorrect {
                completionManager.markStepCompleted(step, cells: step.cells)
            }
            return isCorrect
        }
        
        return false
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Left half - Code viewer
                VStack(spacing: 8) {
                    // Title and description
                    Text(question.title)
                        .font(.system(.title, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.top, 30)
                    
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
                    .padding(.horizontal, 20)
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
                    zoomPanState: zoomPanState,
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
                    isCompleted: isCurrentStepCompleted
                )
                .id(visualizationKey)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    print("\nDataStructureView appeared in VisualizationQuestionView:")
                    print("Current step index: \(currentStepIndex)")
                    print("Current step is multiple choice: \(currentStep.isMultipleChoice)")
                    print("Current step multiple choice answers: \(currentStep.multipleChoiceAnswers)")
                    print("Current step correct answer: \(currentStep.multipleChoiceCorrectAnswer)")
                    print("Selected answer: \(selectedAnswer)")
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
                                .foregroundColor(((currentStep.userInputRequired || currentStep.isMultipleChoice) && !isCurrentStepCompleted && !completionManager.isStepCompleted(currentStep)) ? Color.gray : Color.blue)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                        }
                    }
                    .disabled(((currentStep.userInputRequired || currentStep.isMultipleChoice) && !isCurrentStepCompleted && !completionManager.isStepCompleted(currentStep)))
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
    
    private func moveToNextStep() {
        print("\n=== Moving to Next Step ===")
        
        // Mark current step as completed if it's not already
        if !completionManager.isStepCompleted(currentStep) {
            if currentStep.isMultipleChoice {
                completionManager.markStepCompleted(currentStep, answer: selectedAnswer)
            } else {
                completionManager.markStepCompleted(currentStep, cells: currentStep.cells)
            }
        }
        
        let nextIndex = currentStepIndex + 1
        guard nextIndex < steps.count else { return }
        
        currentStepIndex = nextIndex
        selectedAnswer = ""  // Always reset selected answer when navigating
        
        visualizationKey = UUID()
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
