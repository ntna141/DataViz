import SwiftUI

struct ReviewScreen: View {
    let review: String
    let onNext: () -> Void
    let onBackToMap: () -> Void
    
    init(review: String, onNext: @escaping () -> Void, onBackToMap: @escaping () -> Void) {
        print("ReviewScreen initialized with review: \(review)")  // Added debug log
        self.review = review
        self.onNext = onNext
        self.onBackToMap = onBackToMap
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Great Job!")
                .font(.system(.title, design: .monospaced))
                .fontWeight(.bold)
            
            // Review text with shadow box style
            ZStack {
                // Shadow layer
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
                
                Text(review)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.horizontal)
            
            VStack(spacing: 15) {
                // Next button
                Button(action: onNext) {
                    ZStack {
                        // Shadow layer
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        // Main button
                        Rectangle()
                            .fill(Color.blue)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                            )
                        
                        Text("Start Next Question")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .buttonStyle(.plain)
                
                // Back to Map button
                Button(action: onBackToMap) {
                    ZStack {
                        // Shadow layer
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        // Main button
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                            )
                        
                        Text("Back to Map")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct LevelDetailView: View {
    let level: LevelEntity
    @Environment(\.presentationMode) var presentationMode
    @State private var showingVisualization = false
    @State private var showingReview = false
    @State private var visualization: VisualizationQuestion?
    @State private var currentQuestionIndex = 0
    @State private var visualizationQuestions: [QuestionEntity] = []
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Level \(level.number)")
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main button
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .buttonStyle(.plain)
                }
                
                // Topic
                Text(level.topic ?? "")
                    .font(.system(.title2, design: .monospaced))
                
                // Description box
                ZStack {
                    // Shadow layer
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
                    
                    Text(level.desc ?? "")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.black)
                        .padding()
                }
                .frame(height: 100)
                
                // Continue button
                if visualization != nil {
                    Button(action: {
                        showingVisualization = true
                    }) {
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main button
                            Rectangle()
                                .fill(Color.blue)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                            
                            Text("Continue Visualization")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Load all visualization questions
            if let questions = level.questions?.allObjects as? [QuestionEntity] {
                visualizationQuestions = questions
                    .filter { $0.type == "visualization" }
                    .sorted { $0.orderIndex < $1.orderIndex }
                loadCurrentQuestion()
            }
        }
        .fullScreenCover(isPresented: $showingVisualization) {
            if let visualization = visualization {
                VisualizationQuestionView(
                    question: visualization,
                    questionEntity: visualizationQuestions[currentQuestionIndex],
                    onComplete: {
                        let questionId = visualizationQuestions[currentQuestionIndex].uuid!
                        GameProgressionManager.shared.markQuestionCompleted(questionId)
                        showingVisualization = false
                        showingReview = true
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showingReview) {
            if let visualization = visualization {
                ReviewScreen(
                    review: visualization.review,
                    onNext: {
                        showingReview = false
                        moveToNextQuestion()
                    },
                    onBackToMap: {
                        showingReview = false
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func loadCurrentQuestion() {
        guard currentQuestionIndex < visualizationQuestions.count else {
            visualization = nil
            showingVisualization = false
            return
        }
        
        let question = visualizationQuestions[currentQuestionIndex]
        visualization = VisualizationManager.shared.loadVisualization(for: question)
        print("Review content:", visualization?.review ?? "no review available")
    }
    
    private func moveToNextQuestion() {
        // First reset current visualization
        visualization = nil
        
        // Then load next question
        currentQuestionIndex += 1
        loadCurrentQuestion()
        
        // Show new visualization if available
        if visualization != nil {
            showingVisualization = true
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let level = LevelEntity(context: context)
    level.number = 1
    level.topic = "Linked Lists"
    level.desc = "Learn about linked lists and how to build them step by step."
    level.isUnlocked = true
    level.uuid = UUID()
    
    return LevelDetailView(level: level)
} 
