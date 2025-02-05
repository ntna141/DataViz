import SwiftUI

struct ReviewScreen: View {
    let review: String
    let onNext: () -> Void
    let onBackToMap: () -> Void
    
    var body: some View {
        ZStack {
            // Full screen white background
            Color.white
                .ignoresSafeArea()
            
            // Center content with device-specific width
            GeometryReader { geometry in
                ScrollView {
                    // Main Card
                    ZStack {
                        // Shadow layer
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        // Main background
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                            )
                        
                        // Content
                        VStack(spacing: 30) {
                            Text("Great Job!")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                            
                            // Review text box
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
                            .frame(height: 120)
                            
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
                                .frame(width: 250, height: 50)
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
                                .frame(width: 250, height: 50)
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(40)
                    }
                    .padding(10) // Padding around the entire card to show shadow
                    .padding(.top, 90)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.85 : nil)
                    .frame(minHeight: geometry.size.height * 0.6)
                    .padding(.vertical, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
        ZStack {
            // Full screen white background
            Color.white
                .ignoresSafeArea()
            
            // Center content with device-specific width
            GeometryReader { geometry in
                ScrollView {
                    // Main Card with padding for shadow
                    ZStack {
                        // Shadow layer
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        // Main background
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                            )
                        
                        // Content
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
                            .frame(height: 120)
                            
                            // Continue button
                            if visualization != nil {
                                HStack {
                                    Spacer()
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
                                    .frame(width: 250, height: 50)
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
                            }
                        }
                        .padding(40)
                    }
                    .padding(10) // Padding around the entire card to show shadow
                    .padding(.top, 90)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.85 : nil)
                    .frame(minHeight: geometry.size.height * 0.6)
                    .padding(.vertical, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Review overlay
            if showingReview, let visualization = visualization {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
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
        .onAppear {
            // Load all visualization questions
            if let questions = level.questions?.allObjects as? [QuestionEntity] {
                visualizationQuestions = questions
                    .filter { $0.type == "visualization" }
                    .sorted { $0.orderIndex < $1.orderIndex }
                loadCurrentQuestion()
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
