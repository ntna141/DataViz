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
    @State private var showingGuide = false
    @State private var currentGuideStep = 0
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
        
        
        let defaults = UserDefaults.standard
        let hasSeenGuide = defaults.bool(forKey: "hasSeenDataStructureGuide")
        if !hasSeenGuide {
            defaults.set(true, forKey: "hasSeenDataStructureGuide")
            defaults.synchronize()
        }
        _showingGuide = State(initialValue: !hasSeenGuide)
        _currentGuideStep = State(initialValue: 0)
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
                    onShowGuide: {
                        showingGuide = true
                    },
                    shouldHideButtons: $showingGuide,
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
                if !showingGuide {
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
            
            
            if showingGuide {
                GeometryReader { geometry in
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingGuide = false
                            }
                        
                        GuideCard(
                            currentStep: currentGuideStep,
                            onNext: {
                                currentGuideStep += 1
                                resetDroppedElementsForCurrentStep()
                            },
                            onBack: {
                                currentGuideStep = max(0, currentGuideStep - 1)
                                resetDroppedElementsForCurrentStep()
                            },
                            onClose: {
                                showingGuide = false
                                currentGuideStep = 0
                                resetDroppedElementsForCurrentStep()
                                UserDefaults.standard.set(true, forKey: "hasSeenDataStructureGuide")
                            },
                            geometry: geometry,
                            elementListState: elementListState
                        )
                        .environmentObject(cellSizeManager)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
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
    
    private func resetDroppedElementsForCurrentStep() {
        if let elements = currentStep.availableElements {
            elementListState.hardReset(with: elements)
        }
    }
}

private struct GuideCard: View {
    let currentStep: Int
    let onNext: () -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    let geometry: GeometryProxy
    @ObservedObject var elementListState: ElementListState
    @EnvironmentObject private var cellSizeManager: CellSizeManager
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Guide")
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                
                ScrollView {
                    if currentStep == 0 {
                        VStack(alignment: .leading, spacing: 25) {
                            Text("Button Functions")
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .padding(.bottom, 5)
                            
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                Text("Autoplay")
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding(.bottom, 5)
                            
                            Text("Autoplay will automatically move through steps (the pause is based on the length of the text) until it reaches a question")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.leading)
                                .padding(.bottom, 20)
                            
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text("Reset")
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding(.bottom, 5)
                            
                            Text("Reset the current step to its original state if you've moved elements around")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.leading)
                                .padding(.bottom, 10)
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                Text("Show Answer")
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding(.bottom, 5)
                            
                            Text("If you have answered a question before, this button will show, and you can either move on or click it to show the correct answer")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.leading)
                                .padding(.bottom, 5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                    } else if currentStep == 1 {
                        VStack(alignment: .leading, spacing: 25) {
                            Text("Drag and Drop")
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .padding(.bottom, 10)
                            
                            Text("You can drag elements between cells or to/from the element list to create the correct data structure:")
                                .font(.system(.body, design: .monospaced))
                                .padding(.bottom, 10)

                            
                            HStack(spacing: 50) {
                                
                                VStack(spacing: 35) {
                                    VStack(alignment: .center, spacing: 25) {
                                        HStack(spacing: cellSizeManager.size * 0.5) {
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .offset(x: 6, y: 6)
                                                
                                                Rectangle()
                                                    .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                    )
                                                Text("1")
                                                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                            }
                                            
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .offset(x: 6, y: 6)
                                                
                                                Rectangle()
                                                    .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                    )
                                                Text("?")
                                                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                            }
                                        }
                                        
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.black)
                                                .offset(x: 6, y: 6)
                                            
                                            Rectangle()
                                                .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                )
                                            
                                            HStack(spacing: cellSizeManager.size * 0.2) {
                                                ForEach(["2", "3"], id: \.self) { element in
                                                    ZStack {
                                                        Rectangle()
                                                            .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                            .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                            .overlay(
                                                                Rectangle()
                                                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                            )
                                                        Text(element)
                                                            .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, cellSizeManager.size * 0.2)
                                        }
                                        .frame(width: cellSizeManager.size * 4, height: cellSizeManager.size * 1.2)
                                    }
                                    
                                    Text("Drag cell (3) from the list to the empty cell (?) to make it cell (3). If you drag it to cell (1), it will replace cell (1) and cell (1) will go to the list.")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(width: 300)
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                
                                
                                VStack(spacing: 35) {
                                    VStack(alignment: .center, spacing: 25) {
                                        HStack(spacing: cellSizeManager.size * 0.5) {
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .offset(x: 6, y: 6)
                                                
                                                Rectangle()
                                                    .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                    )
                                                Text("4")
                                                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                            }
                                            
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .offset(x: 6, y: 6)
                                                
                                                Rectangle()
                                                    .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                    )
                                                Text("5")
                                                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                            }
                                        }
                                        
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.black)
                                                .offset(x: 6, y: 6)
                                            
                                            Rectangle()
                                                .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                )
                                            
                                            Text("Drop here to remove")
                                                .font(.system(size: cellSizeManager.size * 0.35))
                                                .foregroundColor(.gray)
                                                .monospaced()
                                        }
                                        .frame(width: cellSizeManager.size * 4, height: cellSizeManager.size * 1.2)
                                    }
                                    
                                    Text("Drag any cell to the empty list below to remove it from the structure and add it to the list.")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .frame(width: 300)
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                            .padding(.vertical, 30)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if currentStep == 2 {
                        VStack(alignment: .leading, spacing: 25) {
                            Text("Multiple Choice Questions")
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .padding(.bottom, 10)
                            
                            Text("Some steps will present multiple choice questions. Select the correct answer to proceed:")
                                .font(.system(.body, design: .monospaced))
                                .padding(.bottom, 20)
                            
                            VStack(spacing: 25) {
                                Text("What is the first element?")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.bottom, 20)
                                
                                HStack(spacing: cellSizeManager.size * 0.5) {
                                    ForEach(["1", "2"], id: \.self) { value in
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.black)
                                                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                .offset(x: 6, y: 6)
                                            
                                            Rectangle()
                                                .fill(value == "1" ? Color.blue : Color(red: 0.96, green: 0.95, blue: 0.91))
                                                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                )
                                            Text(value)
                                                .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                                .foregroundColor(value == "1" ? .white : .primary)
                                        }
                                    }
                                }
                                .padding(.bottom, 20)
                                
                            }
                            .padding(.vertical, 20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                        HStack(spacing: 100) {  
                            
                        Button(action: onBack) {
                            buttonBackground {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .foregroundColor(currentStep == 0 ? .gray : .blue)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 120, height: 40)
                        .disabled(currentStep == 0)
                            
                            
                            Button(action: {
                                if currentStep == 2 {
                                    onClose()
                                } else {
                                    elementListState.reset(with: [])
                                    onNext()
                                }
                            }) {
                                buttonBackground {
                                    HStack {
                                        Text(currentStep == 2 ? "Complete" : "Next")
                                        if currentStep < 2 {
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                    .foregroundColor(.blue)
                                    .font(.system(.body, design: .monospaced).weight(.bold))
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 120, height: 40)
                        }
                        .padding(.top, 30)

            }
            .padding(50)
            .background(
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
                }
            )
            .frame(width: 800, height: 800)
            .fixedSize()
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
