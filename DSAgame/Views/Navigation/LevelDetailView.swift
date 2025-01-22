import SwiftUI

struct LevelDetailView: View {
    let level: Level
    @State private var selectedQuestionType: QuestionType?
    
    var body: some View {
        VStack(spacing: 20) {
            // Level Info
            VStack(alignment: .leading) {
                Text("Level \(level.number): \(level.topic)")
                    .font(.title)
                Text(level.description)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Question Types Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(QuestionType.allCases, id: \.self) { type in
                    QuestionTypeCard(type: type, question: level.questions[type])
                        .onTapGesture {
                            selectedQuestionType = type
                        }
                }
            }
            .padding()
        }
        .sheet(item: $selectedQuestionType) { type in
            if let question = level.question(for: type) {
                QuestionView(question: question)
            }
        }
    }
}

struct QuestionTypeCard: View {
    let type: QuestionType
    let question: Question?
    
    var body: some View {
        VStack {
            Image(systemName: type.icon)
                .font(.system(size: 30))
            Text(type.rawValue.capitalized)
                .font(.headline)
            if let question = question {
                HStack {
                    ForEach(0..<question.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
} 