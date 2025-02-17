import SwiftUI
import GameplayKit

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
                        VStack(spacing: 30) {
                            Text("Great Job!")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .padding(.top, 50)
                            
                            Spacer()
                                .frame(height: 20)
                            
                            // Review text box
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
                                        .padding(30)
                                }
                            }
                            .frame(minHeight: 300, maxHeight: geometry.size.height * 0.6)
                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                                .frame(height: 40)
                            
                            // Buttons with restored retro styling
                            VStack(spacing: 25) {
                                ZStack {
                                    // Shadow
                                    Text("Start Next Question")
                                        .font(.system(.title3, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .offset(x: 6, y: 6)
                                    
                                    // Main button
                                    Button(action: onNext) {
                                        Text("Start Next Question")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    }
                                }
                                
                                ZStack {
                                    // Shadow
                                    Text("Back to Map")
                                        .font(.system(.title3, design: .monospaced))
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .offset(x: 6, y: 6)
                                    
                                    // Main button
                                    Button(action: onBackToMap) {
                                        Text("Back to Map")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 50)
                        }
                        .padding(40)
                    }
                    .padding(10)
                    .padding(.top, 20)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.95 : nil)
                    .frame(minHeight: geometry.size.height * 0.85)
                    .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct LevelDetailView: View {
    let level: LevelData.Level
    @Environment(\.presentationMode) var presentationMode
    @State private var showingVisualization = false
    @State private var showingReview = false
    @State private var visualization: VisualizationQuestion?
    @State private var currentQuestionIndex = 0
    @State private var visualizationQuestions: [LevelData.Question] = []
    @State private var isLoading = true
    
    // Helper function to slugify topic name
    private func slugify(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
    }
    
    // Helper function to get pastel color based on level
    private func getPastelColors(for level: Int) -> (Color, Color, Color) {
        let colors: [(Color, Color, Color)] = [
            (Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.4, green: 0.5, blue: 0.9), Color(red: 0.9, green: 0.4, blue: 0.5)),  // Light blue bg, Dark blue, Dark pink
            (Color(red: 0.95, green: 1.0, blue: 0.9), Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.7, green: 0.4, blue: 0.8)),  // Light green bg, Dark green, Purple
            (Color(red: 1.0, green: 0.95, blue: 0.9), Color(red: 0.9, green: 0.5, blue: 0.3), Color(red: 0.3, green: 0.6, blue: 0.8)),  // Light peach bg, Dark orange, Dark blue
            (Color(red: 0.95, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.8, blue: 0.6))   // Light purple bg, Dark purple, Dark teal
        ]
        let index = (level - 1) % colors.count
        return colors[index]
    }
    
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
                                
                                // Close button with retro styling
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
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                        
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .buttonStyle(.plain)
                            }
                            
                            // Question list with retro styling
                            if !visualizationQuestions.isEmpty {
                                ForEach(visualizationQuestions.indices, id: \.self) { index in
                                    let question = visualizationQuestions[index]
                                    let isCompleted = GameProgressionManager.shared.isQuestionCompleted("\(level.number)-\(index)")
                                    Button(action: {
                                        if let vis = VisualizationManager.shared.createVisualization(from: question) {
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
                                                .fill(isCompleted ? Color(red: 0.9, green: 1.0, blue: 0.9) : Color.white)
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(Color.black, lineWidth: 2)
                                                )
                                            
                                            HStack {
                                                Text("\(index + 1). \(question.title)")
                                                    .font(.system(.body, design: .monospaced))
                                                    .foregroundColor(isCompleted ? Color(white: 0.1) : .primary)
                                                
                                                Spacer()
                                                
                                                if isCompleted {
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
                        .padding(40)
                    }
                    .padding(10)
                    .padding(.top, 20)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.95 : nil)
                    .frame(minHeight: geometry.size.height * 0.85)
                    .padding(.vertical, 20)
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
            if let vis = visualization {
                let questionId = "\(level.number)-\(currentQuestionIndex)"
                VisualizationQuestionView(
                    question: vis,
                    questionId: questionId,
                    onComplete: {
                        GameProgressionManager.shared.markQuestionCompleted(questionId)
                        showingVisualization = false
                        showingReview = true
                    },
                    isCompleted: GameProgressionManager.shared.isQuestionCompleted(questionId)
                )
            }
        }
        .onAppear {
            isLoading = true
            // Load all visualization questions
            visualizationQuestions = level.questions.filter { $0.type == "visualization" }
            isLoading = false
        }
    }
    
    private func moveToNextQuestion() {
        currentQuestionIndex += 1
        if currentQuestionIndex < visualizationQuestions.count,
           let vis = VisualizationManager.shared.createVisualization(from: visualizationQuestions[currentQuestionIndex]) {
            visualization = vis
            showingVisualization = true
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct QuestionCard: View {
    let title: String
    let description: String
    let difficulty: Int
    let isCompleted: Bool
    let accentColor1: Color
    let accentColor2: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(isCompleted ? .gray : .primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(isCompleted ? .gray : .secondary)
                    .lineLimit(2)
                
                HStack {
                    ForEach(0..<difficulty, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(isCompleted ? .gray : accentColor1)
                    }
                }
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 2)
        )
    }
}

