import SwiftUI

struct CodeLine: Identifiable {
    let id = UUID()
    let number: Int
    let content: String
    var syntaxTokens: [SyntaxToken]
    var isHighlighted: Bool = false
    var sideComment: String? = nil
}

struct SyntaxToken: Identifiable {
    let id = UUID()
    let text: String
    let type: TokenType
}

enum TokenType {
    case keyword
    case identifier
    case string
    case number
    case punctuation
    case comment
    case whitespace
    
    var color: Color {
        switch self {
        case .keyword:
            return .blue
        case .identifier:
            return .primary
        case .string:
            return .green
        case .number:
            return .orange
        case .punctuation:
            return .gray
        case .comment:
            return .gray
        case .whitespace:
            return .clear
        }
    }
}

struct SyntaxParser {
    static func parse(_ code: String) -> [SyntaxToken] {
        // This is a simple implementation - you can make it more sophisticated
        let words = code.split(separator: " ")
        return words.map { word in
            let text = String(word)
            let type: TokenType
            
            switch text {
            case "func", "let", "var", "class", "struct", "enum", "if", "else", "for", "while", "return":
                type = .keyword
            case _ where text.allSatisfy { $0.isNumber }:
                type = .number
            case _ where text.hasPrefix("\"") && text.hasSuffix("\""):
                type = .string
            case "{", "}", "(", ")", ".", "=", ",", ";":
                type = .punctuation
            case _ where text.hasPrefix("//"):
                type = .comment
            case "":
                type = .whitespace
            default:
                type = .identifier
            }
            
            return SyntaxToken(text: text, type: type)
        }
    }
} 