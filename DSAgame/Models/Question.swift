import Foundation

public struct Question: Identifiable, Codable {
    public let id: UUID
    public let type: QuestionType
    public let title: String
    public let description: String
    public let difficulty: Difficulty
    public var isCompleted: Bool
    public var stars: Int
    public var bestTime: TimeInterval?
    public var attempts: Int
    
    public enum Difficulty: Int, Codable, CaseIterable {
        case easy = 1
        case medium = 2
        case hard = 3
        case expert = 4
        
        public var description: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            case .expert: return "Expert"
            }
        }
        
        public var maxStars: Int {
            return self.rawValue * 3
        }
    }
    
    public init(type: QuestionType, title: String, description: String, difficulty: Difficulty) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.isCompleted = false
        self.stars = 0
        self.bestTime = nil
        self.attempts = 0
    }
} 