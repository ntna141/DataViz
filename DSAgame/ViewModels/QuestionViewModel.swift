import Foundation

class QuestionViewModel: ObservableObject {
    let question: Question
    @Published var isComplete: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    private var startTime: Date?
    
    init(question: Question) {
        self.question = question
    }
    
    func startTimer() {
        startTime = Date()
    }
    
    func complete(stars: Int) {
        guard !isComplete else { return }
        isComplete = true
        if let startTime = startTime {
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
} 