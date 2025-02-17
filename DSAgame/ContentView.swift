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
                LazyVGrid(columns: columns, spacing: 80) {
                    ForEach(levels.prefix(10), id: \.number) { level in
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
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text(level.description)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer()  // Push all content to the top
                                }
                                .padding(20)
                            }
                            .frame(height: 200)  // Increased height to accommodate more text
                            
                            // Add decorative background between Header and Questions
                            decorativeBackground(for: Int32(level.number))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                                .padding(.vertical, 10)
                            
                            // Questions list
                            VStack(spacing: 30) {
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
                .padding(.vertical, 60)  // Keep vertical centering
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
    
    private func slugify(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
    }
    
    private func getPastelColors(for level: Int32) -> (Color, Color, Color) {
        let colors: [(Color, Color, Color)] = [
            (Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.4, green: 0.5, blue: 0.9), Color(red: 0.9, green: 0.4, blue: 0.5)),
            (Color(red: 0.95, green: 1.0, blue: 0.9), Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.7, green: 0.4, blue: 0.8)),
            (Color(red: 1.0, green: 0.95, blue: 0.9), Color(red: 0.9, green: 0.5, blue: 0.3), Color(red: 0.3, green: 0.6, blue: 0.8)),
            (Color(red: 0.95, green: 0.9, blue: 1.0), Color(red: 0.7, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.8, blue: 0.6))
        ]
        let index = Int(level - 1) % colors.count
        return colors[index]
    }
    
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
                   
               default:  // Root pattern
                   // Start from center top
                   let rootOrigin = CGPoint(x: centerX, y: safeRect.minY + padding)
                   
                   // Create multiple branching roots
                   let numMainRoots = 4
                   for i in 0..<numMainRoots {
                       // Wider angle spread (0.4π to 1.3π instead of 0.7π to π)
                       let angle = 2*Double.pi * (0.4 + Double(i) * 0.9 / Double(numMainRoots-1))
                       // Increased length by 50%
                       let mainLength = maxRadius * 2.4
                       
                       var rootPath = Path()
                       rootPath.move(to: rootOrigin)
                       
                       // Create curved main root
                       let endX = centerX + cos(angle) * mainLength
                       let endY = rootOrigin.y + sin(angle) * mainLength
                       
                       // Adjusted control points for longer, more spread out curves
                       let ctrl1X = centerX + cos(angle) * mainLength * 0.2
                       let ctrl1Y = rootOrigin.y + sin(angle) * mainLength * 0.2
                       let ctrl2X = centerX + cos(angle) * mainLength * 0.6
                       let ctrl2Y = rootOrigin.y + sin(angle) * mainLength * 0.6
                       
                       rootPath.addCurve(
                           to: CGPoint(x: endX, y: endY),
                           control1: CGPoint(x: ctrl1X, y: ctrl1Y),
                           control2: CGPoint(x: ctrl2X, y: ctrl2Y)
                       )
                       
                       context.stroke(rootPath, with: .color(color2.opacity(0.8)), lineWidth: 3)
                       
                       // Add branches
                       let numBranches = 5  // Increased number of branches
                       for j in 1...numBranches {
                           let t = Double(j) / Double(numBranches + 1)
                           let branchStartX = centerX + cos(angle) * (mainLength * t)
                           let branchStartY = rootOrigin.y + sin(angle) * (mainLength * t)
                           
                           // Create two branches, one on each side
                           for side in [-1, 1] {
                               // Increased angle spread for branches
                               let branchAngle = angle + Double(side) * Double.pi * 0.3
                               let branchLength = mainLength * (1.0 - t) * 0.7  // Increased branch length
                               
                               var branch = Path()
                               branch.move(to: CGPoint(x: branchStartX, y: branchStartY))
                               let branchEndX = branchStartX + cos(branchAngle) * branchLength
                               let branchEndY = branchStartY + sin(branchAngle) * branchLength
                               
                               // Increased curve intensity for branches
                               let branchCtrlX = branchStartX + cos(branchAngle) * branchLength * 0.5
                               let branchCtrlY = branchStartY + sin(branchAngle) * branchLength * 0.5
                               
                               branch.addQuadCurve(
                                   to: CGPoint(x: branchEndX, y: branchEndY),
                                   control: CGPoint(x: branchCtrlX + Double(side) * 30, y: branchCtrlY)
                               )
                               
                               context.stroke(branch, with: .color(color3.opacity(0.7)), lineWidth: 2)
                               
                               // Add smaller branches with curves
                               if branchLength > maxRadius * 0.2 {
                                   let numSubBranches = 2
                                   for _ in 1...numSubBranches {
                                       let subStartX = branchStartX + (branchEndX - branchStartX) * 0.5
                                       let subStartY = branchStartY + (branchEndY - branchStartY) * 0.5
                                       // Increased angle spread for sub-branches
                                       let subAngle = branchAngle + Double(side) * Double.pi * 0.25
                                       let subLength = branchLength * 0.5  // Increased sub-branch length
                                       
                                       var subBranch = Path()
                                       subBranch.move(to: CGPoint(x: subStartX, y: subStartY))
                                       let subEndX = subStartX + cos(subAngle) * subLength
                                       let subEndY = subStartY + sin(subAngle) * subLength
                                       
                                       // Increased curve intensity for sub-branches
                                       let subCtrlX = subStartX + cos(subAngle) * subLength * 0.5
                                       let subCtrlY = subStartY + sin(subAngle) * subLength * 0.5
                                       
                                       subBranch.addQuadCurve(
                                           to: CGPoint(x: subEndX, y: subEndY),
                                           control: CGPoint(x: subCtrlX + Double(side) * 15, y: subCtrlY)
                                       )
                                       
                                       context.stroke(subBranch, with: .color(color3.opacity(0.6)), lineWidth: 1.5)
                                   }
                               }
                           }
                       }
                   }
               }
           }
           .padding(4)  // Add padding to show the full border
           .frame(maxWidth: .infinity)
           .frame(height: 192)  // 200 - 8 to account for padding
           .clipped()
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
        .frame(height: 60)  // Reduced height since we removed description
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
