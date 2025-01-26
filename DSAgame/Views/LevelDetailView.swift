import SwiftUI

struct ReviewScreen: View {
    let review: String
    let onNext: () -> Void
    let onBackToMap: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Great Job!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(review)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            VStack(spacing: 15) {
                Button(action: onNext) {
                    Text("Start Next Question")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: onBackToMap) {
                    Text("Back to Map")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top)
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
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Topic
                Text(level.topic ?? "")
                    .font(.title2)
                
                // Description
                Text(level.desc ?? "")
                    .font(.body)
                    .foregroundColor(.gray)
                
                // Start button
                if visualization != nil {
                    Button(action: {
                        showingVisualization = true
                    }) {
                        Text("Continue Visualization")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Load all visualization questions
            if let questions = level.questions?.allObjects as? [QuestionEntity] {
                visualizationQuestions = questions.filter { $0.type == "visualization" }
                loadCurrentQuestion()
            }
        }
        .fullScreenCover(isPresented: $showingVisualization) {
            if let visualization = visualization {
                VisualizationQuestionView(question: visualization) {
                    let questionId = visualizationQuestions[currentQuestionIndex].uuid!
                    GameProgressionManager.shared.markQuestionCompleted(questionId)
                    showingVisualization = false
                    showingReview = true
                }
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