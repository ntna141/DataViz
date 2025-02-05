import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isShowingMap = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.blue.opacity(0.1).ignoresSafeArea()
                
                HStack {  // Changed from VStack to HStack for better landscape layout
                    VStack {
                        Text("DSA Adventure")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                            .padding()
                        
                        Text("Master Data Structures & Algorithms")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(.bottom, 50)
                        
                        NavigationLink(destination: MapView(), isActive: $isShowingMap) {
                            Text("Start Adventure")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 250, height: 60)
                                .background(Color.blue)
                                .cornerRadius(30)
                                .shadow(radius: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Optional: Add additional content for the right side of the screen
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)  // Added to prevent split view in landscape
    }
}

struct MapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: LevelEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \LevelEntity.number, ascending: true)]
    ) private var levels: FetchedResults<LevelEntity>
    
    var body: some View {
        ScrollView {
            ZStack {
                // Darker beige background
                Color(red: 0.90, green: 0.87, blue: 0.82).ignoresSafeArea()
                
                // Main vertical line
                Path { path in
                    path.move(to: CGPoint(x: 75, y: 0))  // Moved line more left
                    path.addLine(to: CGPoint(x: 75, y: 1600))
                }
                .stroke(Color.black, lineWidth: 8)
                
                // Horizontal markers at each level
                VStack(spacing: 150) {
                    ForEach(Array(levels.prefix(10)), id: \.uuid) { level in
                        HStack(spacing: -20) { // Negative spacing to connect marker to line
                            Rectangle()
                                .fill(Color.brown)
                                .frame(width: 50, height: 8)
                            
                            LevelMarker(level: level)
                        }
                    }
                }
                .offset(x: 75, y: 100) // Moved markers left and added top offset
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(Color(red: 0.90, green: 0.87, blue: 0.82))
        .onAppear {
    GameProgressionManager.shared.updateLevelLocks()
}
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

// Preview provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
