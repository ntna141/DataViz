import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isShowingMap = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.white.ignoresSafeArea()
                
                // Add floating data structures
                FloatingArrayView()
                    .opacity(0.15)
                FloatingLinkedListView()
                    .opacity(0.15)
                FloatingBinaryTreeView()
                    .opacity(0.15)
                
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
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: LevelEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LevelEntity.number, ascending: true)]
    ) private var levels: FetchedResults<LevelEntity>
    
    // Define grid layout with increased spacing
    private let columns = [
        GridItem(.flexible(), spacing: 40), // Increased spacing between columns
        GridItem(.flexible(), spacing: 40),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading) {
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
                
                // Existing LazyVGrid
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(Array(levels.prefix(10)), id: \.uuid) { level in
                        Button(action: {
                            let detailView = LevelDetailView(level: level)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootViewController = window.rootViewController {
                                let hostingController = UIHostingController(rootView: detailView)
                                hostingController.modalPresentationStyle = .fullScreen
                                rootViewController.present(hostingController, animated: true)
                            }
                        }) {
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
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Level \(level.number)")
                                        .font(.system(.title, design: .monospaced))
                                        .fontWeight(.bold)
                                    
                                    Text(level.topic ?? "")
                                        .font(.system(.title2, design: .monospaced))
                                        .lineLimit(1)
                                    
                                    Text(level.desc ?? "")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding(.top, 5)
                                        .lineLimit(3)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Add checkmark for completed level
                                if GameProgressionManager.shared.isLevelCompleted(Int(level.number)) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.green)
                                        .padding([.top, .trailing], 20)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                }
                            }
                            .frame(height: 180)
                            .background(
                                GameProgressionManager.shared.isLevelCompleted(Int(level.number)) ?
                                    Color(red: 0.9, green: 1.0, blue: 0.9) :
                                    Color.white
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 30)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

struct LevelMarker: View {
    let level: LevelEntity
    @State private var showingDetail = false
    
    var body: some View {
        VStack {
            Button(action: {
                showingDetail = true
            }) {
                ZStack {
                    Rectangle()
                        .fill(level.isUnlocked ? Color(red: 0.2, green: 0.6, blue: 0.6) : Color.gray)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 3)
                    
                    Text("\(level.number)")
                        .foregroundColor(.white)
                        .font(.title2.bold())
                }
            }
            
            Text(level.topic ?? "Topic")
                .font(.caption)
                .foregroundColor(.black)
        }
        .fullScreenCover(isPresented: $showingDetail) {
            LevelDetailView(level: level)
        }
    }
}

// New floating array view
struct FloatingArrayView: View {
    @State private var position: CGPoint
    @State private var angle: Double = 0
    @State private var velocity = CGVector(dx: 1, dy: 1)
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    let cellCount = 5
    let speed: Double = 0.65
    
    // Initialize with random position
    init() {
        let randomX = CGFloat.random(in: 200...(UIScreen.main.bounds.width - 200))
        let randomY = CGFloat.random(in: 200...(UIScreen.main.bounds.height - 200))
        _position = State(initialValue: CGPoint(x: randomX, y: randomY))
        
        // Random initial velocity
        let randomAngle = Double.random(in: 0...(2 * .pi))
        _velocity = State(initialValue: CGVector(
            dx: cos(randomAngle),
            dy: sin(randomAngle)
        ))
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Draw cells
                for index in 0..<cellCount {
                    let cellSize: CGFloat = 40
                    let spacing: CGFloat = 10
                    let totalWidth = CGFloat(cellCount) * cellSize + CGFloat(cellCount - 1) * spacing
                    let startX = -totalWidth/2
                    
                    let x = startX + CGFloat(index) * (cellSize + spacing)
                    
                    let cellRect = CGRect(
                        x: x,
                        y: -cellSize/2,
                        width: cellSize,
                        height: cellSize
                    )
                    
                    var path = Path(roundedRect: cellRect, cornerRadius: 0)
                    
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: position.x, y: position.y)
                    transform = transform.rotated(by: angle)
                    path = path.applying(transform)
                    
                    // Draw cell - white fill with thin black stroke (no shadow)
                    context.fill(path, with: .color(.white))
                    context.stroke(path, with: .color(.blue), lineWidth: 2)
                }
            }
        }
        .onReceive(timer) { _ in
            // Smooth movement using velocity
            position.x += velocity.dx * speed
            position.y += velocity.dy * speed
            
            // Bounce off screen edges with padding
            let padding: CGFloat = 200
            if position.x < padding || position.x > UIScreen.main.bounds.width - padding {
                velocity.dx *= -1
                // Add slight vertical variation when bouncing horizontally
                velocity.dy += Double.random(in: -0.1...0.1)
            }
            if position.y < padding || position.y > UIScreen.main.bounds.height - padding {
                velocity.dy *= -1
                // Add slight horizontal variation when bouncing vertically
                velocity.dx += Double.random(in: -0.1...0.1)
            }
            
            // Normalize velocity to maintain consistent speed
            let length = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            velocity.dx /= length
            velocity.dy /= length
            
            // Update angle to match movement direction
            angle = atan2(velocity.dy, velocity.dx)
        }
    }
}

struct FloatingLinkedListView: View {
    @State private var position: CGPoint
    @State private var velocity = CGVector(dx: 1, dy: 1)
    @State private var angle: Double = 0
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    let nodeCount = 4
    let speed: Double = 0.65
    
    // Initialize with random position
    init() {
        let randomX = CGFloat.random(in: 200...(UIScreen.main.bounds.width - 200))
        let randomY = CGFloat.random(in: 200...(UIScreen.main.bounds.height - 200))
        _position = State(initialValue: CGPoint(x: randomX, y: randomY))
        
        // Random initial velocity
        let randomAngle = Double.random(in: 0...(2 * .pi))
        _velocity = State(initialValue: CGVector(
            dx: cos(randomAngle),
            dy: sin(randomAngle)
        ))
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Draw nodes and arrows
                for index in 0..<nodeCount {
                    let nodeSize: CGFloat = 40
                    let spacing: CGFloat = 20
                    let totalWidth = CGFloat(nodeCount) * nodeSize + CGFloat(nodeCount - 1) * spacing
                    let startX = -totalWidth/2
                    
                    let x = startX + CGFloat(index) * (nodeSize + spacing)
                    
                    let nodeRect = CGRect(
                        x: x,
                        y: -nodeSize/2,
                        width: nodeSize,
                        height: nodeSize
                    )
                    
                    var nodePath = Path(roundedRect: nodeRect, cornerRadius: 0)
                    
                    // Draw arrow if not the last node
                    if index < nodeCount - 1 {
                        let arrowStart = CGPoint(x: x + nodeSize, y: 0)
                        let arrowEnd = CGPoint(x: x + nodeSize + spacing, y: 0)
                        
                        var arrowPath = Path()
                        arrowPath.move(to: arrowStart)
                        arrowPath.addLine(to: arrowEnd)
                        
                        let arrowheadLength: CGFloat = 10
                        let arrowheadAngle: CGFloat = .pi / 6
                        arrowPath.move(to: arrowEnd)
                        arrowPath.addLine(to: CGPoint(
                            x: arrowEnd.x - arrowheadLength * cos(arrowheadAngle),
                            y: arrowEnd.y - arrowheadLength * sin(arrowheadAngle)
                        ))
                        arrowPath.move(to: arrowEnd)
                        arrowPath.addLine(to: CGPoint(
                            x: arrowEnd.x - arrowheadLength * cos(-arrowheadAngle),
                            y: arrowEnd.y - arrowheadLength * sin(-arrowheadAngle)
                        ))
                        
                        var transform = CGAffineTransform.identity
                        transform = transform.translatedBy(x: position.x, y: position.y)
                        transform = transform.rotated(by: angle)
                        let transformedArrowPath = arrowPath.applying(transform)
                        
                        context.stroke(transformedArrowPath, with: .color(.blue), lineWidth: 2)
                    }
                    
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: position.x, y: position.y)
                    transform = transform.rotated(by: angle)
                    nodePath = nodePath.applying(transform)
                    
                    // Draw node - white fill with thin black stroke (no shadow)
                    context.fill(nodePath, with: .color(.white))
                    context.stroke(nodePath, with: .color(.blue), lineWidth: 2)
                }
            }
        }
        .onReceive(timer) { _ in
            // Same movement logic as FloatingArrayView
            position.x += velocity.dx * speed
            position.y += velocity.dy * speed
            
            let padding: CGFloat = 200
            if position.x < padding || position.x > UIScreen.main.bounds.width - padding {
                velocity.dx *= -1
                velocity.dy += Double.random(in: -0.1...0.1)
            }
            if position.y < padding || position.y > UIScreen.main.bounds.height - padding {
                velocity.dy *= -1
                velocity.dx += Double.random(in: -0.1...0.1)
            }
            
            let length = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            velocity.dx /= length
            velocity.dy /= length
            
            angle = atan2(velocity.dy, velocity.dx)
        }
    }
}

struct FloatingBinaryTreeView: View {
    @State private var positions: [CGPoint]
    @State private var velocities: [CGVector]
    @State private var angles: [Double]
    
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    let speed: Double = 0.65
    
    // Initialize with random positions in different screen sections
    init() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Initialize arrays with 4 different positions, velocities, and angles
        var initialPositions: [CGPoint] = []
        var initialVelocities: [CGVector] = []
        var initialAngles: [Double] = []
        
        // Create 4 different starting positions, one in each quadrant
        for i in 0...3 {
            let (x, y) = switch i {
                case 0: // Top-left
                    (CGFloat.random(in: 200...screenWidth/2 - 200),
                     CGFloat.random(in: 200...screenHeight/2 - 200))
                case 1: // Top-right
                    (CGFloat.random(in: screenWidth/2 + 200...screenWidth - 200),
                     CGFloat.random(in: 200...screenHeight/2 - 200))
                case 2: // Bottom-left
                    (CGFloat.random(in: 200...screenWidth/2 - 200),
                     CGFloat.random(in: screenHeight/2 + 200...screenHeight - 200))
                default: // Bottom-right
                    (CGFloat.random(in: screenWidth/2 + 200...screenWidth - 200),
                     CGFloat.random(in: screenHeight/2 + 200...screenHeight - 200))
            }
            
            let randomAngle = Double.random(in: 0...(2 * .pi))
            initialPositions.append(CGPoint(x: x, y: y))
            initialVelocities.append(CGVector(
                dx: cos(randomAngle),
                dy: sin(randomAngle)
            ))
            initialAngles.append(randomAngle)
        }
        
        _positions = State(initialValue: initialPositions)
        _velocities = State(initialValue: initialVelocities)
        _angles = State(initialValue: initialAngles)
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Define constants first
                let nodeSize: CGFloat = 30
                let levelSpacing: CGFloat = 80
                let horizontalSpacing: CGFloat = 45
                
                // Draw all trees
                for treeIndex in 0..<4 {
                    let trees = [
                        // First tree - long right branch
                        [
                            (CGPoint(x: -180, y: 0), true),                    // Root
                            (CGPoint(x: -220, y: levelSpacing), false),        // Left child
                            (CGPoint(x: -140, y: levelSpacing), true),         // Right child
                            (CGPoint(x: -160, y: levelSpacing*2), true),       // Right-left
                            (CGPoint(x: -140, y: levelSpacing*3), true),       // Deep branch
                            (CGPoint(x: -120, y: levelSpacing*4), false),      // Deepest node
                        ],
                        // Second tree - zigzag pattern
                        [
                            (CGPoint(x: -60, y: 0), true),                     // Root
                            (CGPoint(x: -90, y: levelSpacing), true),          // Left branch
                            (CGPoint(x: -60, y: levelSpacing*2), true),        // Left-right
                            (CGPoint(x: -90, y: levelSpacing*3), true),        // Zigzag
                            (CGPoint(x: -60, y: levelSpacing*4), false),       // Bottom
                        ],
                        // Third tree - left-heavy
                        [
                            (CGPoint(x: 60, y: 0), true),                      // Root
                            (CGPoint(x: 30, y: levelSpacing), true),           // Left child
                            (CGPoint(x: 0, y: levelSpacing*2), true),          // Left-left
                            (CGPoint(x: -30, y: levelSpacing*3), true),        // Left-left-left
                            (CGPoint(x: -60, y: levelSpacing*4), false),       // Deepest left
                            (CGPoint(x: 90, y: levelSpacing), false),          // Right child
                        ],
                        // Fourth tree - right-heavy with split
                        [
                            (CGPoint(x: 180, y: 0), true),                     // Root
                            (CGPoint(x: 160, y: levelSpacing), false),         // Left child
                            (CGPoint(x: 200, y: levelSpacing), true),          // Right child
                            (CGPoint(x: 180, y: levelSpacing*2), true),        // Right-left
                            (CGPoint(x: 220, y: levelSpacing*2), true),        // Right-right
                            (CGPoint(x: 200, y: levelSpacing*3), false),       // Deep node
                            (CGPoint(x: 240, y: levelSpacing*3), false),       // Deep node
                        ]
                    ]
                    
                    let tree = trees[treeIndex]
                    
                    // Draw connections
                    var connectionsPath = Path()
                    
                    // Connect nodes based on their positions
                    for i in 1..<tree.count {
                        let childPos = tree[i].0
                        for j in 0..<i {
                            let parentPos = tree[j].0
                            if parentPos.y == childPos.y - levelSpacing &&
                               abs(parentPos.x - childPos.x) <= horizontalSpacing * 1.5 {
                                connectionsPath.move(to: parentPos)
                                connectionsPath.addLine(to: childPos)
                            }
                        }
                    }
                    
                    var transform = CGAffineTransform.identity
                    transform = transform.translatedBy(x: positions[treeIndex].x, y: positions[treeIndex].y)
                    transform = transform.rotated(by: angles[treeIndex])
                    let transformedConnections = connectionsPath.applying(transform)
                    
                    // Draw connections
                    context.stroke(transformedConnections, with: .color(.blue), lineWidth: 2)
                    
                    // Draw nodes
                    for (nodePosition, isParent) in tree {
                        let nodeRect = CGRect(
                            x: nodePosition.x - nodeSize/2,
                            y: nodePosition.y - nodeSize/2,
                            width: nodeSize,
                            height: nodeSize
                        )
                        
                        var nodePath = Path(roundedRect: nodeRect, cornerRadius: 0)
                        nodePath = nodePath.applying(transform)
                        
                        context.fill(nodePath, with: .color(.white))
                        context.stroke(nodePath, with: .color(.blue), lineWidth: 2)
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            // Update each tree's position independently
            for i in 0..<4 {
                positions[i].x += velocities[i].dx * speed
                positions[i].y += velocities[i].dy * speed
                
                let padding: CGFloat = 200
                if positions[i].x < padding || positions[i].x > UIScreen.main.bounds.width - padding {
                    velocities[i].dx *= -1
                    velocities[i].dy += Double.random(in: -0.1...0.1)
                }
                if positions[i].y < padding || positions[i].y > UIScreen.main.bounds.height - padding {
                    velocities[i].dy *= -1
                    velocities[i].dx += Double.random(in: -0.1...0.1)
                }
                
                let length = sqrt(velocities[i].dx * velocities[i].dx + velocities[i].dy * velocities[i].dy)
                velocities[i].dx /= length
                velocities[i].dy /= length
                
                angles[i] = atan2(velocities[i].dy, velocities[i].dx)
            }
        }
    }
}

// Preview provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
