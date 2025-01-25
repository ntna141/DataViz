import SwiftUI

struct LevelDetailView: View {
    let level: LevelEntity
    @Environment(\.presentationMode) var presentationMode
    @State private var showingVisualization = false
    @State private var visualization: VisualizationQuestion?
    @State private var selectedQuestionIndex = 0
    
    var questions: [QuestionEntity] {
        (level.questions?.allObjects as? [QuestionEntity])?.sorted { q1, q2 in
            q1.type == "visualization" && q2.type == "debugging"
        } ?? []
    }
    
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
                
                // Question Picker
                if !questions.isEmpty {
                    Picker("Question", selection: $selectedQuestionIndex) {
                        ForEach(Array(questions.enumerated()), id: \.element.uuid) { index, question in
                            Text("\(question.type?.capitalized ?? "") \(index + 1)")
                                .tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Question Description
                    if let question = questions[safe: selectedQuestionIndex] {
                        Text(question.title ?? "")
                            .font(.headline)
                        Text(question.desc ?? "")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
                
                // Start Button
                if let visualization = visualization {
                    Button(action: {
                        showingVisualization = true
                    }) {
                        Text("Start \(visualization.type.capitalized)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(visualization.type == "debugging" ? Color.orange : Color.blue)
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
        .onChange(of: selectedQuestionIndex) { newIndex in
            loadVisualization(for: newIndex)
        }
        .onAppear {
            loadVisualization(for: selectedQuestionIndex)
        }
        .fullScreenCover(isPresented: $showingVisualization) {
            if let visualization = visualization {
                if visualization.type == "debugging" {
                    DebuggingQuestionView(question: visualization)
                } else {
                    VisualizationQuestionView(question: visualization)
                }
            }
        }
    }
    
    private func loadVisualization(for index: Int) {
        guard let question = questions[safe: index] else { return }
        visualization = VisualizationManager.shared.loadVisualization(for: question)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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