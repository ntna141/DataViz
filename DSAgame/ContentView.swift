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

// Preview provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
