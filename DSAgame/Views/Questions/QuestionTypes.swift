import SwiftUI

struct CodingQuestion: View {
    @ObservedObject var viewModel: QuestionViewModel
    
    var body: some View {
        Text("Coding Question - Coming Soon")
    }
}

struct MultipleChoiceQuestion: View {
    @ObservedObject var viewModel: QuestionViewModel
    
    var body: some View {
        Text("Multiple Choice Question - Coming Soon")
    }
}

struct AnalysisQuestion: View {
    @ObservedObject var viewModel: QuestionViewModel
    
    var body: some View {
        Text("Analysis Question - Coming Soon")
    }
} 