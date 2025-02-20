import Foundation
import SwiftUI


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
    @State private var steps: [VisualizationStep]  
    @State private var visualizationKey = UUID()
    @State private var showingHint = false
    @State private var selectedAnswer: String = ""
    @StateObject private var completionManager = VisualizationCompletionManager()
    @State private var isAutoPlaying = false
    @State private var autoPlayTimer: Timer?
    @StateObject private var cellSizeManager = CellSizeManager()
    @StateObject private var elementListState = ElementListState()
    @StateObject private var originalCellsState: OriginalCellsState
    
    init(question: VisualizationQuestion, questionId: String, onComplete: @escaping () -> Void = {}, isCompleted: Bool = false) {
        self.question = question
        self.questionId = questionId
        self.onComplete = onComplete
        self.isCompleted = isCompleted
        _steps = State(initialValue: question.steps)  
        
        let firstStep = question.steps[0]
        _originalCellsState = StateObject(wrappedValue: OriginalCellsState(cells: firstStep.cells))

    }
    
    private var currentStep: VisualizationStep {
        let step = steps[currentStepIndex]
        return step
    }
    
    private func updateCurrentStep(_ step: VisualizationStep) {
        steps[currentStepIndex] = step
        visualizationKey = UUID()
        
        
        originalCellsState.hardReset(with: step.cells)
        
        
        if let elements = step.availableElements {
            elementListState.hardReset(with: elements)
        }
    }
    
    private var isCurrentStepCompleted: Bool {
        let step = currentStep
        
        
        if step.isMultipleChoice {
            
            if completionManager.isStepCompleted(step) {
                return true
            }
            
            
            return selectedAnswer == step.multipleChoiceCorrectAnswer
        }
        
        
        if step.userInputRequired {
            
            if completionManager.isStepCompleted(step) {
                return true
            }
            
            
            guard let nextStep = steps[safe: currentStepIndex + 1] else { return false }
            return zip(step.cells, nextStep.cells).allSatisfy { current, next in
                if next.value.isEmpty {
                    return current.value.isEmpty
                }
                return current.value == next.value
            }
        }
        
        
        if !completionManager.isStepCompleted(step) {
            completionManager.markStepCompleted(step)
        }
        return true
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                
                VStack(spacing: 8) {
                    
                    Text(question.title)
                        .font(.system(.title, design: .monospaced))
                        .padding(.top, 30)
                        .frame(maxWidth: .infinity * 0.95, alignment: .leading)
                        .padding(.leading, 16)
                    
                    
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
                            selectedAnswer = answer
                        }
                    },
                    selectedMultipleChoiceAnswer: selectedAnswer,
                    onShowAnswer: showAnswer,
                    isCompleted: isCurrentStepCompleted,
                    questionId: questionId,
                    elementListState: elementListState,
                    originalCellsState: originalCellsState
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
            
            
            if showingHint {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingHint = false
                        }
                    
                    ZStack {
                        
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        
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
            
            
            VStack {
                Spacer()
                HStack {
                    
                    Spacer().frame(width: UIScreen.main.bounds.width * 0.25)
                    
                    
                    Button(action: {
                        if currentStepIndex > 0 {
                            let prevIndex = currentStepIndex - 1
                            currentStepIndex = prevIndex
                            selectedAnswer = ""  
                            visualizationKey = UUID()
                        }
                    }) {
                        ZStack {
                            
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            
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
                    
                    
                    Button(action: {
                        if shouldDisableNextButton {
                            onComplete()
                        } else {
                            moveToNextStep()
                        }
                    }) {
                        ZStack {
                            
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            
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
        
        if isCompleted {
            return false
        }
        
        
        if currentStep.userInputRequired || currentStep.isMultipleChoice {
            return !isCurrentStepCompleted
        }
        
        
        return false
    }
    
    private var shouldShowComplete: Bool {
        
        
        
        
        isLastStep && (
            isCompleted ||
            isCurrentStepCompleted ||
            (!currentStep.userInputRequired && !currentStep.isMultipleChoice)
        )
    }
    
    private var shouldShowAnswerButton: Bool {
        
        
        
        isCompleted && (currentStep.isMultipleChoice || currentStep.userInputRequired)
    }
    
    private func moveToNextStep() {
        
        if isLastStep && (isCompleted || isCurrentStepCompleted) {
            onComplete()
            return
        }
        
        
        if !isCompleted && !isCurrentStepCompleted {
            return
        }
        
        
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
        
        
        selectedAnswer = ""  
        visualizationKey = UUID()  
        
        
        currentStepIndex = nextIndex
        
        
        let nextStep = steps[nextIndex]
        originalCellsState.hardReset(with: nextStep.cells)
        
        
        if isCompleted {
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
            
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
            
            
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
        
        autoPlayTimer?.invalidate()
        
        
        let interval = calculateAutoPlayInterval(comment: currentStep.lineComment)
        
        
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [self] _ in
            if isAutoPlaying && !isLastStep && !currentStep.userInputRequired {
                moveToNextStep()
                
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
        
    }
    
    private func calculateAutoPlayInterval(comment: String?) -> TimeInterval {
        guard let comment = comment else { return 3.0 }  
        
        
        let baseInterval: TimeInterval = 2.0
        
        
        let additionalTime = TimeInterval(comment.count) * 0.05
        
        
        return min(max(baseInterval + additionalTime, 2.0), 7.0)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
