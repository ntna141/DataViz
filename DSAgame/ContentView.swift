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
                
                VStack {
                    Spacer()
                    
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
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
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
                // Background - treasure map style
                Color(red: 0.95, green: 0.9, blue: 0.8).ignoresSafeArea()
                
                // Path connecting levels
                Path { path in
                    // Start at first level
                    path.move(to: CGPoint(x: 50, y: 100))
                    
                    // Create a winding path
                    for i in 1...10 {
                        let x = i % 2 == 0 ? CGFloat(300) : CGFloat(50)
                        let y = CGFloat(i) * 150
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.brown, style: StrokeStyle(lineWidth: 4, dash: [10]))
                
                // Level markers
                VStack(spacing: 50) {
                    ForEach(Array(levels.prefix(10)), id: \.uuid) { level in
                        LevelMarker(level: level)
                            .offset(x: CGFloat(Int(level.number) % 2 == 0 ? 125 : -125))
                    }
                }
                .padding(.top, 100)
            }
        }
        .navigationTitle("Adventure Map")
    }
}

struct LevelMarker: View {
    let level: LevelEntity
    @State private var showingDetail = false
    
    var body: some View {
        VStack {
            Button(action: {
                if level.isUnlocked {
                    showingDetail = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(level.isUnlocked ? Color.blue : Color.gray)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 3)
                    
                    Text("\(level.number)")
                        .foregroundColor(.white)
                        .font(.title2.bold())
                }
            }
            .disabled(!level.isUnlocked)
            
            Text(level.topic ?? "Topic")
                .font(.caption)
                .foregroundColor(.black)
        }
        .sheet(isPresented: $showingDetail) {
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
