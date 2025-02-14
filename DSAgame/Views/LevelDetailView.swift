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
    let level: LevelEntity
    @Environment(\.presentationMode) var presentationMode
    @State private var showingVisualization = false
    @State private var showingReview = false
    @State private var visualization: VisualizationQuestion?
    @State private var currentQuestionIndex = 0
    @State private var visualizationQuestions: [QuestionEntity] = []
    @State private var isLoading = true
    @State private var visualizations: [VisualizationQuestion?] = []
    
    // Helper function to slugify topic name
    private func slugify(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
    }
    
    // Helper function to get pastel color based on level
    private func getPastelColors(for level: Int32) -> (Color, Color, Color) {
        let colors: [(Color, Color, Color)] = [
            (Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.4, green: 0.5, blue: 0.9), Color(red: 0.9, green: 0.4, blue: 0.5)),  // Light blue bg, Dark blue, Dark pink
            (Color(red: 0.95, green: 1.0, blue: 0.9), Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.7, green: 0.4, blue: 0.8)),  // Light green bg, Dark green, Purple
            (Color(red: 1.0, green: 0.95, blue: 0.9), Color(red: 0.9, green: 0.5, blue: 0.3), Color(red: 0.3, green: 0.6, blue: 0.8)),  // Light peach bg, Dark orange, Dark blue
            (Color(red: 0.95, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.8, blue: 0.6))   // Light purple bg, Dark purple, Dark teal
        ]
        let index = Int(level - 1) % colors.count
        return colors[index]
    }
    
    // Helper function to draw decorative background
    private func decorativeBackground(for level: Int32) -> some View {
        let (color1, color2, color3) = getPastelColors(for: level)
        
        return Canvas { context, size in
            // Background
            let backgroundRect = CGRect(origin: .zero, size: size)
            context.fill(Path(backgroundRect), with: .color(color1))
            
            // Calculate safe drawing area (slightly smaller than frame to prevent overflow)
            let padding: CGFloat = 10
            let safeRect = CGRect(x: padding, y: padding, 
                                width: size.width - padding * 2, 
                                height: size.height - padding * 2)
            let centerX = safeRect.midX
            let centerY = safeRect.midY
            let maxRadius = min(safeRect.width, safeRect.height) * 0.4
            
            switch Int(level) % 4 {
            case 0:  // Explosion pattern
                // Draw radiating lines
                for i in 0..<16 {
                    let angle = Double(i) * .pi / 8
                    var path = Path()
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    let endX = centerX + cos(angle) * maxRadius
                    let endY = centerY + sin(angle) * maxRadius
                    path.addLine(to: CGPoint(x: endX, y: endY))
                    context.stroke(path, with: .color(color2.opacity(0.8)), lineWidth: 3)
                }
                
                // Draw concentric circles
                for i in 1...4 {
                    let radius = maxRadius * Double(i) / 4
                    let rect = CGRect(x: centerX - radius, y: centerY - radius, 
                                    width: radius * 2, height: radius * 2)
                    context.stroke(Path(ellipseIn: rect), with: .color(color3.opacity(0.8)), lineWidth: 2)
                }
                
            case 1:  // Geometric pattern
                let gridSize = 4  // Reduced from 5 to make shapes larger
                let cellWidth = safeRect.width / Double(gridSize)
                let cellHeight = safeRect.height / Double(gridSize)
                
                for row in 0..<gridSize {
                    for col in 0..<gridSize {
                        let x = safeRect.minX + Double(col) * cellWidth
                        let y = safeRect.minY + Double(row) * cellHeight
                        
                        if (row + col) % 2 == 0 {
                            // Draw circles
                            let radius = min(cellWidth, cellHeight) * 0.35
                            let rect = CGRect(x: x + cellWidth/2 - radius, y: y + cellHeight/2 - radius,
                                            width: radius * 2, height: radius * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(color2.opacity(0.8)))
                        } else {
                            // Draw rotated squares
                            let squareSize = min(cellWidth, cellHeight) * 0.5
                            var path = Path(CGRect(x: -squareSize/2, y: -squareSize/2, 
                                                 width: squareSize, height: squareSize))
                            let transform = CGAffineTransform(translationX: x + cellWidth/2, y: y + cellHeight/2)
                                .rotated(by: .pi/4)
                            path = path.applying(transform)
                            context.fill(path, with: .color(color3.opacity(0.8)))
                        }
                    }
                }
                
            case 2:  // Wave interference pattern
                for i in 0..<3 {
                    var path = Path()
                    let yOffset = safeRect.minY + safeRect.height * (0.25 + Double(i) * 0.25)
                    path.move(to: CGPoint(x: safeRect.minX, y: yOffset))
                    
                    for x in stride(from: safeRect.minX, through: safeRect.maxX, by: 5) {
                        let phase = Double(i) * .pi / 3
                        let y = yOffset + sin(x / 30 + phase) * 12
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    context.stroke(path, with: .color(color2.opacity(0.8)), lineWidth: 2.5)
                }
                
                // Add crossing waves
                for i in 0..<3 {
                    var path = Path()
                    let xOffset = safeRect.minX + safeRect.width * (0.25 + Double(i) * 0.25)
                    path.move(to: CGPoint(x: xOffset, y: safeRect.minY))
                    
                    for y in stride(from: safeRect.minY, through: safeRect.maxY, by: 5) {
                        let phase = Double(i) * .pi / 3
                        let x = xOffset + sin(y / 30 + phase) * 12
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    context.stroke(path, with: .color(color3.opacity(0.8)), lineWidth: 2.5)
                }
                
            default:  // Spiral pattern
                for i in 0..<3 {
                    var path = Path()
                    let startAngle = Double(i) * .pi * 2 / 3
                    path.move(to: CGPoint(x: centerX, y: centerY))
                    
                    for t in stride(from: 0, to: 6 * .pi, by: 0.1) {
                        let radius = t * maxRadius / (6 * .pi)
                        let x = centerX + cos(t + startAngle) * radius
                        let y = centerY + sin(t + startAngle) * radius
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    let color = i == 0 ? color2 : color3
                    context.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 2.5)
                }
            }
        }
        .padding(4)  // Add padding to show the full border
        .frame(maxWidth: .infinity)
        .frame(height: 192)  // 200 - 8 to account for padding
        .clipped()
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
                            // Data Structure Visualization Header
                            ZStack {
                                // Black frame with thicker border
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 4)
                                
                                // Decorative background
                                decorativeBackground(for: level.number)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .padding(.horizontal, 20)
                            .clipped()
                            .padding(.bottom, 20)
                            .padding(.top, -90)
                            
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
                    .padding(.top, 20)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.85 : nil)
                    .frame(minHeight: geometry.size.height * 0.7)
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
