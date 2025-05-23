import SwiftUI

struct CodeLine: Identifiable {
    let id = UUID()
    let number: Int
    let content: String
    var isHighlighted: Bool = false
    var sideComment: String? = nil
    var syntaxTokens: [SyntaxToken] = []
}

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

struct SyntaxParser {
    static let keywords = Set([
        "func", "var", "let", "if", "else", "for", "while", "return",
        "guard", "switch", "case", "break", "continue", "class", "struct",
        "enum", "protocol", "extension", "import", "init"
    ])
    
    static func parse(_ line: String) -> [SyntaxToken] {
        guard !line.isEmpty else { return [] }
        
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
            return [SyntaxToken(text: line, type: .comment)]
        }
        
        var tokens: [SyntaxToken] = []
        var currentToken = ""
        
        func addToken(_ text: String) {
            guard !text.isEmpty else { return }
            let type: SyntaxToken.TokenType
            
            if keywords.contains(text) {
                type = .keyword
            } else if text.hasSuffix("()") {
                type = .function
            } else if text == ":" || text == "," || text == "(" || text == ")" || text == "{" || text == "}" {
                type = .plain
            } else if text == "Int" || text == "String" || text == "Node" {
                type = .type
            } else if text.allSatisfy({ $0.isWhitespace }) {
                type = .plain
            } else {
                type = .variable
            }
            
            tokens.append(SyntaxToken(text: text, type: type))
        }
        
        var index = line.startIndex
        while index < line.endIndex {
            let char = line[index]
            
            if char.isWhitespace {
                addToken(currentToken)
                currentToken = ""
                addToken(String(char))
            } else if "():,{}".contains(char) {
                addToken(currentToken)
                currentToken = ""
                addToken(String(char))
            } else {
                currentToken.append(char)
            }
            
            index = line.index(after: index)
        }
        
        addToken(currentToken)
        
        return tokens
    }
}

extension Character {
    var isPunctuation: Bool {
        return [".", ":", "=", "?", "(", ")", "{", "}", "[", "]", ",", ";"].contains(self)
    }
}

struct CodeLineView: View {
    let line: CodeLine
    let maxLineNumberWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 0) {
                Text("\(line.number)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(minWidth: maxLineNumberWidth, alignment: .trailing)
                    .lineLimit(1)
                    .padding(.trailing, 8)
                
                if !line.syntaxTokens.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(line.syntaxTokens) { token in
                            Text(token.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(token.type.color)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(line.content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 2)
            .background(line.isHighlighted ? Color.yellow.opacity(0.2) : Color.clear)
            
            if let comment = line.sideComment {
                Text("// \(comment)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.leading, maxLineNumberWidth + 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(nil)
            }
        }
    }
}

struct CodeViewer: View {
    let lines: [CodeLine]
    
    private var maxLineNumberWidth: CGFloat {
        let maxDigits = String(lines.count).count
        return CGFloat(maxDigits) * 10
    }
    
    private var highlightedLineNumber: Int? {
        lines.first(where: { $0.isHighlighted })?.number
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("</> python")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(lines) { line in
                            CodeLineView(line: line, maxLineNumberWidth: maxLineNumberWidth)
                                .id(line.number)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                }
                .onChange(of: highlightedLineNumber) { newLineNumber in
                    if let lineNumber = newLineNumber {
                        withAnimation {
                            proxy.scrollTo(lineNumber, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                .mask(
                    VStack(spacing: 0) {
                        Rectangle().frame(height: 1)
                        HStack(spacing: 0) {
                            Rectangle().frame(width: 1)
                            Spacer()
                            Rectangle().frame(width: 1)
                        }
                        Spacer()
                    }
                )
        )
    }
}

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