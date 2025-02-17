import SwiftUI

struct ContentView: View {
    @State private var isShowingMap = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.white.ignoresSafeArea()
                
                // Add hexagonal graph - now with opacity control
                HexagonalGraphView()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .opacity(0.2)
                
                HStack {
                    VStack {
                        // Title Card
                        ZStack {
                            // Shadow layer
                            Text("DataViz")
                                .font(.system(size: 100, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .tracking(10)
                                .offset(x: 8, y: 8)
                            
                            // Main text
                            Text("DataViz")
                                .font(.system(size: 100, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                                .tracking(10)
                                .padding()
                        }
                        
                        Text("Data Structures through Visualization")
                            .font(.system(size: 40, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.bottom, 50)
                        
                        // Start Journey Button
                        NavigationLink(destination: MapView(), isActive: $isShowingMap) {
                            ZStack {
                                // Shadow
                                Text("Start Journey")
                                    .font(.system(.title, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 250, height: 60)
                                    .background(Color.blue)
                                    .offset(x: 8, y: 8)
                                
                                // Main button
                                Text("Start Journey")
                                    .font(.system(.title, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 250, height: 60)
                                    .background(Color.blue)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

struct MapView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var levels: [LevelData.Level] = []
    @State private var showingVisualization = false
    @State private var visualization: VisualizationQuestion?
    @State private var currentQuestionIndex = 0
    @State private var visualizationQuestions: [LevelData.Question] = []
    @State private var showingReview = false
    @State private var selectedLevelNumber: Int?
    
    // Define grid layout with 3 columns
    private let columns = [
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Back button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    ZStack {
                        // Shadow layer
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 150, height: 50)
                            .offset(x: 6, y: 6)
                        
                        // Main background
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 150, height: 50)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                            )
                        
                        // Content
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.black)
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                .padding(.horizontal, 50)
                
                // Levels Grid
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(levels.prefix(10), id: \.number) { level in
                        // Level Card
                        VStack(spacing: 20) {
                            // Level Header
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
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        Text("Level \(level.number)")
                                            .font(.system(.title, design: .monospaced))
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        if GameProgressionManager.shared.isLevelCompleted(level.number) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    Text(level.topic)
                                        .font(.system(.title3, design: .monospaced))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(20)
                            }
                            .frame(height: 140)
                            
                            // Questions list
                            VStack(spacing: 15) {
                                ForEach(level.questions.indices, id: \.self) { index in
                                    let question = level.questions[index]
                                    if question.type == "visualization" {
                                        Button(action: {
                                            if let vis = VisualizationManager.shared.createVisualization(from: question) {
                                                visualization = vis
                                                currentQuestionIndex = index
                                                selectedLevelNumber = level.number
                                                showingVisualization = true
                                            }
                                        }) {
                                            QuestionRow(
                                                index: index,
                                                question: question,
                                                isCompleted: GameProgressionManager.shared.isQuestionCompleted("\(level.number)-\(index)")
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 50)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .fullScreenCover(
            isPresented: Binding(
                get: { showingVisualization && visualization != nil },
                set: { showingVisualization = $0 }
            )
        ) {
            if let vis = visualization {
                let questionId = "\(selectedLevelNumber ?? 0)-\(currentQuestionIndex)"
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
        .overlay(
            // Review overlay
            Group {
                if showingReview, let visualization = visualization {
                    ReviewScreen(
                        review: visualization.review,
                        onNext: {
                            showingReview = false
                            moveToNextQuestion()
                        },
                        onBackToMap: {
                            showingReview = false
                            selectedLevelNumber = nil
                        }
                    )
                }
            }
        )
        .onAppear {
            levels = GameProgressionManager.shared.getLevels()
        }
    }
    
    private func moveToNextQuestion() {
        currentQuestionIndex += 1
        if let levelNumber = selectedLevelNumber,
           let level = levels.first(where: { $0.number == levelNumber }),
           currentQuestionIndex < level.questions.count,
           let vis = VisualizationManager.shared.createVisualization(from: level.questions[currentQuestionIndex]) {
            visualization = vis
            showingVisualization = true
        } else {
            selectedLevelNumber = nil
        }
    }
}

struct QuestionRow: View {
    let index: Int
    let question: LevelData.Question
    let isCompleted: Bool
    
    var body: some View {
        ZStack {
            // Shadow layer
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
            
            // Main background
            Rectangle()
                .fill(isCompleted ? Color(red: 0.9, green: 1.0, blue: 0.9) : Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                )
            
            HStack(alignment: .center, spacing: 10) {
                Text("\(index + 1). \(question.title)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isCompleted ? Color(white: 0.1) : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .frame(height: 70)
    }
}

// Replace FloatingArrayView, FloatingLinkedListView, and FloatingBinaryTreeView with:
struct HexagonalGraphView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Debug - fill background to see canvas bounds
                let background = Path(CGRect(origin: .zero, size: size))
                
                let centerX = size.width / 2
                let centerY = size.height / 2
                let cellSize: CGFloat = 40
                let verticalSpacing: CGFloat = 150
                let horizontalSpacing: CGFloat = 180
                
                // Define layers of the graph (now with 7 layers)
                let layers: [[CGPoint]] = [
                    // New top outer layer (10 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 4.5, y: -verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 3.5, y: -verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 2.5, y: -verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 1.5, y: -verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 0.5, y: -verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 0.5, y: -verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 1.5, y: -verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 2.5, y: -verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 3.5, y: -verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 4.5, y: -verticalSpacing * 3),
                    ],
                    // Previous top outer layer (8 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 3.5, y: -verticalSpacing * 2),
                        CGPoint(x: -horizontalSpacing * 2.5, y: -verticalSpacing * 2),
                        CGPoint(x: -horizontalSpacing * 1.5, y: -verticalSpacing * 2),
                        CGPoint(x: -horizontalSpacing * 0.5, y: -verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 0.5, y: -verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 1.5, y: -verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 2.5, y: -verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 3.5, y: -verticalSpacing * 2),
                    ],
                    // Top middle layer (6 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 2.5, y: -verticalSpacing),
                        CGPoint(x: -horizontalSpacing * 1.5, y: -verticalSpacing),
                        CGPoint(x: -horizontalSpacing * 0.5, y: -verticalSpacing),
                        CGPoint(x: horizontalSpacing * 0.5, y: -verticalSpacing),
                        CGPoint(x: horizontalSpacing * 1.5, y: -verticalSpacing),
                        CGPoint(x: horizontalSpacing * 2.5, y: -verticalSpacing),
                    ],
                    // Center layer (4 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 1.5, y: 0),
                        CGPoint(x: -horizontalSpacing * 0.5, y: 0),
                        CGPoint(x: horizontalSpacing * 0.5, y: 0),
                        CGPoint(x: horizontalSpacing * 1.5, y: 0),
                    ],
                    // Bottom middle layer (6 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 2.5, y: verticalSpacing),
                        CGPoint(x: -horizontalSpacing * 1.5, y: verticalSpacing),
                        CGPoint(x: -horizontalSpacing * 0.5, y: verticalSpacing),
                        CGPoint(x: horizontalSpacing * 0.5, y: verticalSpacing),
                        CGPoint(x: horizontalSpacing * 1.5, y: verticalSpacing),
                        CGPoint(x: horizontalSpacing * 2.5, y: verticalSpacing),
                    ],
                    // Previous bottom outer layer (8 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 3.5, y: verticalSpacing * 2),
                        CGPoint(x: -horizontalSpacing * 2.5, y: verticalSpacing * 2),
                        CGPoint(x: -horizontalSpacing * 1.5, y: verticalSpacing * 2),
                        CGPoint(x: -horizontalSpacing * 0.5, y: verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 0.5, y: verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 1.5, y: verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 2.5, y: verticalSpacing * 2),
                        CGPoint(x: horizontalSpacing * 3.5, y: verticalSpacing * 2),
                    ],
                    // New bottom outer layer (10 nodes)
                    [
                        CGPoint(x: -horizontalSpacing * 4.5, y: verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 3.5, y: verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 2.5, y: verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 1.5, y: verticalSpacing * 3),
                        CGPoint(x: -horizontalSpacing * 0.5, y: verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 0.5, y: verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 1.5, y: verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 2.5, y: verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 3.5, y: verticalSpacing * 3),
                        CGPoint(x: horizontalSpacing * 4.5, y: verticalSpacing * 3),
                    ]
                ]
                
                // Draw connections with alternating colors
                for (index, layerIndex) in (0..<(layers.count - 1)).enumerated() {
                    let currentLayer = layers[layerIndex]
                    let nextLayer = layers[layerIndex + 1]
                    
                    let connectionColor: Color = index % 2 == 0 ? Color.blue.opacity(0.7) : .blue  // Changed from dark blue
                    
                    for i in 0..<currentLayer.count {
                        for j in 0..<nextLayer.count {
                            let dx = abs(currentLayer[i].x - nextLayer[j].x)
                            if dx <= horizontalSpacing * 1.5 {
                                var connectionsPath = Path()
                                connectionsPath.move(to: CGPoint(
                                    x: centerX + currentLayer[i].x,
                                    y: centerY + currentLayer[i].y
                                ))
                                connectionsPath.addLine(to: CGPoint(
                                    x: centerX + nextLayer[j].x,
                                    y: centerY + nextLayer[j].y
                                ))
                                context.stroke(connectionsPath, with: .color(connectionColor), lineWidth: 1.0)
                            }
                        }
                    }
                }
                
                // Draw nodes with alternating colors
                for (layerIndex, layer) in layers.enumerated() {
                    let borderColor: Color = layerIndex % 2 == 0 ? Color.blue.opacity(0.7) : .blue  // Changed from dark blue
                    
                    for (nodeIndex, point) in layer.enumerated() {
                        let nodeRect = CGRect(
                            x: centerX + point.x - cellSize/2,
                            y: centerY + point.y - cellSize/2,
                            width: cellSize,
                            height: cellSize
                        )
                        
                        let fillColor: Color = nodeIndex % 2 == 0 ? .white : Color.blue.opacity(0.7)  // Changed from dark blue
                        
                        let circlePath = Path(ellipseIn: nodeRect)
                        context.fill(circlePath, with: .color(fillColor))
                        context.stroke(circlePath, with: .color(borderColor), lineWidth: 1.0)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
