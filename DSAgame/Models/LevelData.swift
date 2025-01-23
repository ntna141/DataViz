import Foundation

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
        let steps: [Step]
        
        struct Step: Codable {
            let lineNumber: Int
            let comment: String?
            let userInputRequired: Bool
            let availableElements: [String]
            let nodes: [Node]
            let connections: [Connection]
            
            struct Node: Codable {
                let value: String
                let position: Position
                
                struct Position: Codable {
                    let x: Double
                    let y: Double
                }
            }
            
            struct Connection: Codable {
                let fromIndex: Int
                let toIndex: Int
                let label: String?
            }
        }
    }
} 