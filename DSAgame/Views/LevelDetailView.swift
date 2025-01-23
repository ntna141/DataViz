import SwiftUI

struct LevelDetailView: View {
    let level: LevelEntity
    @Environment(\.presentationMode) var presentationMode
    @State private var showingVisualization = false
    @State private var visualization: VisualizationQuestion?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Level \(level.number)")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Topic
                Text(level.topic ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Description
                Text(level.desc ?? "")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                // Start Visualization Button
                if let visualization = visualization {
                    Button(action: {
                        showingVisualization = true
                    }) {
                        Text("Start Visualization")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                } else {
                    Text("No visualization available")
                        .foregroundColor(.gray)
                        .italic()
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Load visualization from the first question of type "visualization"
            if let questions = level.questions?.allObjects as? [QuestionEntity],
               let visualizationQuestion = questions.first(where: { $0.type == "visualization" }) {
                visualization = VisualizationManager.shared.loadVisualization(for: visualizationQuestion)
            }
        }
        .fullScreenCover(isPresented: $showingVisualization) {
            if let visualization = visualization {
                VisualizationQuestionView(question: visualization)
            }
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