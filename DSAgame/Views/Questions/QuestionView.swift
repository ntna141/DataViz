import SwiftUI

struct QuestionView: View {
    let question: Question
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuestionViewModel
    
    init(question: Question) {
        self.question = question
        _viewModel = StateObject(wrappedValue: QuestionViewModel(question: question))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Question Header
                QuestionHeader(question: question)
                
                // Question Content
                switch question.type {
                case .visualization:
                    DataStructureVisualizationQuestion(viewModel: viewModel)
                case .coding:
                    CodingQuestion(viewModel: viewModel)
                case .multipleChoice:
                    MultipleChoiceQuestion(viewModel: viewModel)
                case .analysis:
                    AnalysisQuestion(viewModel: viewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct QuestionHeader: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.title)
                .font(.title2)
                .bold()
            Text(question.description)
                .foregroundColor(.secondary)
            HStack {
                Label("\(question.difficulty.description)", systemImage: "speedometer")
                Spacer()
                if let bestTime = question.bestTime {
                    Label(String(format: "%.1fs", bestTime), systemImage: "clock")
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
} 