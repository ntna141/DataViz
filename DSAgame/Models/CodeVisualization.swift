import SwiftUI

// Represents a line of code with metadata
struct CodeLine: Identifiable {
    let id = UUID()
    let number: Int
    let content: String
    var isHighlighted: Bool = false
    var sideComment: String? = nil
    var syntaxTokens: [SyntaxToken] = []
}

// Represents a syntax highlighted token
struct SyntaxToken: Identifiable {
    let id = UUID()
    let text: String
    let type: TokenType
    
    enum TokenType {
        case keyword
        case string
        case number
        case comment
        case function
        case type
        case variable
        case plain
        
        var color: Color {
            switch self {
            case .keyword: return .blue
            case .string: return .green
            case .number: return .orange
            case .comment: return .gray
            case .function: return .purple
            case .type: return .red
            case .variable: return .primary
            case .plain: return .primary
            }
        }
    }
}

// Basic syntax highlighting parser
struct SyntaxParser {
    static let keywords = Set([
        "func", "var", "let", "if", "else", "for", "while", "return",
        "guard", "switch", "case", "break", "continue", "class", "struct",
        "enum", "protocol", "extension", "import", "init"
    ])
    
    static let types = Set([
        "Int", "String", "Double", "Bool", "Array", "Dictionary",
        "Set", "Character", "Float", "Void"
    ])
    
    static func parse(_ line: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let words = line.split(separator: " ")
        
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            
            if keywords.contains(String(cleanWord)) {
                tokens.append(SyntaxToken(text: String(word), type: .keyword))
            } else if types.contains(String(cleanWord)) {
                tokens.append(SyntaxToken(text: String(word), type: .type))
            } else if cleanWord.hasPrefix("\"") && cleanWord.hasSuffix("\"") {
                tokens.append(SyntaxToken(text: String(word), type: .string))
            } else if Double(cleanWord) != nil {
                tokens.append(SyntaxToken(text: String(word), type: .number))
            } else if cleanWord.hasSuffix("()") {
                tokens.append(SyntaxToken(text: String(word), type: .function))
            } else if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                tokens.append(SyntaxToken(text: String(word), type: .comment))
            } else {
                tokens.append(SyntaxToken(text: String(word), type: .plain))
            }
        }
        
        return tokens
    }
}

// View for displaying a single line of code
struct CodeLineView: View {
    let line: CodeLine
    let maxLineNumberWidth: CGFloat
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line number
            Text("\(line.number)")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: maxLineNumberWidth, alignment: .trailing)
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Code content
                HStack(spacing: 4) {
                    ForEach(line.syntaxTokens) { token in
                        Text(token.text)
                            .foregroundColor(token.type.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                .background(line.isHighlighted ? Color.yellow.opacity(0.2) : Color.clear)
                
                // Inline comment
                if let comment = line.sideComment {
                    Text("// \(comment)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.leading, 16)
                }
            }
        }
    }
}

// Main code viewer component
struct CodeViewer: View {
    let lines: [CodeLine]
    
    // Calculate the width needed for line numbers
    private var maxLineNumberWidth: CGFloat {
        let maxDigits = String(lines.count).count
        return CGFloat(maxDigits) * 10
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    CodeLineView(line: line, maxLineNumberWidth: maxLineNumberWidth)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

// Example usage and preview
struct CodeViewerExample: View {
    let sampleCode: [CodeLine] = [
        CodeLine(
            number: 1,
            content: "func binarySearch(_ array: [Int], _ target: Int) -> Int? {",
            syntaxTokens: SyntaxParser.parse("func binarySearch(_ array: [Int], _ target: Int) -> Int? {")
        ),
        CodeLine(
            number: 2,
            content: "    var left = 0",
            isHighlighted: true,
            sideComment: "Initialize left pointer",
            syntaxTokens: SyntaxParser.parse("    var left = 0")
        ),
        CodeLine(
            number: 3,
            content: "    var right = array.count - 1",
            syntaxTokens: SyntaxParser.parse("    var right = array.count - 1")
        ),
        CodeLine(
            number: 4,
            content: "    // Main loop",
            syntaxTokens: SyntaxParser.parse("    // Main loop")
        ),
        CodeLine(
            number: 5,
            content: "    while left <= right {",
            syntaxTokens: SyntaxParser.parse("    while left <= right {")
        )
    ]
    
    var body: some View {
        CodeViewer(lines: sampleCode)
            .frame(height: 300)
            .padding()
    }
}

#Preview {
    CodeViewerExample()
} 