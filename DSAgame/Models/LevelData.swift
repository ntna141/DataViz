import Foundation

// JSON decoding models
struct LevelData: Codable {
    let levels: [Level]
    
    struct Level: Codable {
        let number: Int
        let topic: String
        let description: String
        let requiredStars: Int
        let questions: [Question]
    }
    
    struct Question: Codable {
        let type: String
        let title: String
        let description: String
        let difficulty: Int
        let visualization: Visualization?
    }
    
    struct Visualization: Codable {
        let code: [String]
        let dataStructureType: String
        let steps: [Step]
    }
    
    struct Step: Codable {
        let lineNumber: Int
        let comment: String?
        let hint: String?
        let userInputRequired: Bool
        let availableElements: [String]
        let nodes: [Node]
        let connections: [Connection]?
        let isMultipleChoice: Bool?
        let multipleChoiceAnswers: [String]?
        let multipleChoiceCorrectAnswer: String?
    }
    
    struct Node: Codable {
        let value: String
        var isHighlighted: Bool?
        var label: String?
    }
    
    struct Connection: Codable {
        let from: Int
        let to: Int
        let label: String?
        var isHighlighted: Bool?
        var style: String?
    }
} 