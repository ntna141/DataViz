import Foundation

public enum QuestionType: String, Codable, CaseIterable, Identifiable {
    case visualization
    case coding
    case multipleChoice
    case analysis
    
    public var id: String { rawValue }
    
    var features: [String] {
        switch self {
        case .visualization:
            return [
                "Interactive construction",
                "Step-by-step verification",
                "Real-time feedback",
                "Operation constraints"
            ]
        case .coding:
            return [
                "Code review interface",
                "Complexity analysis",
                "Performance metrics",
                "Alternative solutions"
            ]
        case .multipleChoice:
            return [
                "Next-step prediction",
                "Multiple choice options",
                "Explanation system",
                "Pattern recognition"
            ]
        case .analysis:
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
        case .visualization:
            return "Build and verify solutions step by step"
        case .coding:
            return "Analyze and improve solution performance"
        case .multipleChoice:
            return "Practice predicting next steps in algorithms"
        case .analysis:
            return "Identify patterns and select appropriate algorithms"
        }
    }
    
    var icon: String {
        switch self {
        case .visualization: return "eye.fill"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .multipleChoice: return "list.bullet"
        case .analysis: return "chart.line.uptrend.xyaxis"
        }
    }
} 