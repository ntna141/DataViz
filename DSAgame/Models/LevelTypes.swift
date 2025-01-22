import Foundation

public enum LevelType: String, Codable {
    case build
    case optimize
    case predict
    case pattern
    
    var features: [String] {
        switch self {
        case .build:
            return [
                "Interactive construction",
                "Step-by-step verification",
                "Real-time feedback",
                "Operation constraints"
            ]
        case .optimize:
            return [
                "Code review interface",
                "Complexity analysis",
                "Performance metrics",
                "Alternative solutions"
            ]
        case .predict:
            return [
                "Next-step prediction",
                "Multiple choice options",
                "Explanation system",
                "Pattern recognition"
            ]
        case .pattern:
            return [
                "Problem classification",
                "Algorithm selection",
                "Strategy comparison",
                "Time complexity analysis"
            ]
        }
    }
    
    var description: String {
        switch self {
        case .build:
            return "Build and verify solutions step by step"
        case .optimize:
            return "Analyze and improve solution performance"
        case .predict:
            return "Practice predicting next steps in algorithms"
        case .pattern:
            return "Identify patterns and select appropriate algorithms"
        }
    }
} 