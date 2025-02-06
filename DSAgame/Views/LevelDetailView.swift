import SwiftUI

struct ReviewScreen: View {
    let review: String
    let onNext: () -> Void
    let onBackToMap: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack {
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
                        VStack {
                            Text("Great Job!")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .padding(.top, 30)
                            
                            Spacer() // This will push content down from the top
                            
                            // Review text box - centered vertically
                            ScrollView {
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
                            }
                            .frame(height: 200) // Fixed height for review box
                            
                            Spacer() // This will push content up from the bottom
                            
                            // Buttons at the bottom with increased spacing
                            VStack(spacing: 20) {
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
                            .padding(.bottom, 15)
                        }
                        .padding(40)
                    }
                    .padding(10)
                    .padding(.top, 90)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.85 : nil)
                    .frame(minHeight: geometry.size.height * 0.6)
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
    @State private var isLoading = true
    @State private var visualizations: [VisualizationQuestion?] = []
    
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
                            
                            // Question list
                            if !visualizationQuestions.isEmpty {
                                VStack(spacing: 15) {
                                    Text("Questions")
                                        .font(.system(.headline, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 5)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        ForEach(visualizationQuestions.indices, id: \.self) { index in
                                            let question = visualizationQuestions[index]
                                            Button(action: {
                                                if let vis = VisualizationManager.shared.loadVisualization(for: question) {
                                                    visualization = vis
                                                    currentQuestionIndex = index
                                                    showingVisualization = true
                                                }
                                            }) {
                                                ZStack {
                                                    // Shadow layer
                                                    Rectangle()
                                                        .fill(Color.black)
                                                        .offset(x: 6, y: 6)
                                                    
                                                    // Main button
                                                    Rectangle()
                                                        .fill(question.isCompleted ? Color(red: 0.9, green: 1.0, blue: 0.9) : Color.white)
                                                        .overlay(
                                                            Rectangle()
                                                                .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                        )
                                                    
                                                    HStack {
                                                        Text("\(index + 1). \(question.title ?? "")")
                                                            .font(.system(.body, design: .monospaced))
                                                            .foregroundColor(question.isCompleted ? Color(white: 0.1) : .primary)
                                                        
                                                        Spacer()
                                                        
                                                        if question.isCompleted {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(.green)
                                                        }
                                                    }
                                                    .padding(.horizontal, 20)
                                                }
                                            }
                                            .frame(height: 50)
                                            .buttonStyle(.plain)
                                        }
                                    }
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
        .fullScreenCover(
            isPresented: Binding(
                get: { showingVisualization && visualization != nil },
                set: { showingVisualization = $0 }
            )
        ) {
            VisualizationQuestionView(
                question: visualization!,
                questionEntity: visualizationQuestions[currentQuestionIndex],
                onComplete: {
                    let questionId = visualizationQuestions[currentQuestionIndex].uuid!
                    GameProgressionManager.shared.markQuestionCompleted(questionId)
                    showingVisualization = false
                    showingReview = true
                }
            )
        }
        .onAppear {
            isLoading = true
            // Load all visualization questions
            if let questions = level.questions?.allObjects as? [QuestionEntity] {
                visualizationQuestions = questions
                    .filter { $0.type == "visualization" }
                    .sorted { $0.orderIndex < $1.orderIndex }
                
                // Initialize visualizations array with the correct size
                visualizations = Array(repeating: nil, count: visualizationQuestions.count)
                
                // Load all visualizations immediately
                for (index, question) in visualizationQuestions.enumerated() {
                    if let vis = VisualizationManager.shared.loadVisualization(for: question) {
                        visualizations[index] = vis
                    }
                }
            }
            isLoading = false
        }
    }
    
    private func loadCurrentQuestion() {
        guard currentQuestionIndex < visualizationQuestions.count else {
            showingVisualization = false
            return
        }
        
        // Use the preloaded visualization instead of loading on demand
        visualization = visualizations[currentQuestionIndex]
        showingVisualization = visualization != nil
    }
    
    private func moveToNextQuestion() {
        currentQuestionIndex += 1
        loadCurrentQuestion()
        
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
