import Foundation

public struct Level: Identifiable, Codable {
    public let id: UUID
    public let number: Int
    public let topic: String
    public let description: String
    public let requiredStars: Int
    public var isUnlocked: Bool
    public var questions: [QuestionType: Question]
    
    public init(number: Int, topic: String, description: String, requiredStars: Int, questions: [Question]) {
        self.id = UUID()
        self.number = number
        self.topic = topic
        self.description = description
        self.requiredStars = requiredStars
        self.isUnlocked = number == 1  // First level is unlocked by default
        
        // Convert questions array to dictionary by type
        var questionDict: [QuestionType: Question] = [:]
        for question in questions {
            questionDict[question.type] = question
        }
        self.questions = questionDict
    }
    
    public var isCompleted: Bool {
        questions.values.allSatisfy { $0.isCompleted }
    }
    
    public var totalStars: Int {
        questions.values.reduce(0) { $0 + $1.stars }
    }
    
    public var progress: Double {
        Double(questions.values.filter { $0.isCompleted }.count) / Double(QuestionType.allCases.count)
    }
    
    public func question(for type: QuestionType) -> Question? {
        return questions[type]
    }
} 