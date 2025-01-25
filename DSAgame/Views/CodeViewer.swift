import SwiftUI

// View for displaying a single line of code (purely visual)
struct CodeLineView: View {
    let line: CodeLine
    let maxLineNumberWidth: CGFloat
    let isSelected: Bool
    let isHighlighted: Bool
    
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
                
                // Inline comment
                if let comment = line.sideComment {
                    Text("// \(comment)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.leading, 16)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
        .contentShape(Rectangle())  // Make entire view tappable
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue.opacity(0.3)
        } else if isHighlighted {
            return .yellow.opacity(0.2)
        } else {
            return .clear
        }
    }
}

// Main code viewer component
struct CodeViewer: View {
    let lines: [CodeLine]
    let selectedLines: Set<Int>
    let onLineSelected: (Int) -> Void
    
    // Calculate the width needed for line numbers
    private var maxLineNumberWidth: CGFloat {
        let maxDigits = String(lines.count).count
        return CGFloat(maxDigits) * 10
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    CodeLineView(
                        line: line,
                        maxLineNumberWidth: maxLineNumberWidth,
                        isSelected: selectedLines.contains(line.number),
                        isHighlighted: line.isHighlighted
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

// Specialized code viewer for debugging mode
struct DebugCodeViewer: View {
    let lines: [CodeLine]
    @Binding var selectedLines: Set<Int>
    
    // Calculate the width needed for line numbers
    private var maxLineNumberWidth: CGFloat {
        let maxDigits = String(lines.count).count
        return CGFloat(maxDigits) * 10
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines) { line in
                    ZStack {  // Use ZStack to ensure tap area covers everything
                        CodeLineView(
                            line: line,
                            maxLineNumberWidth: maxLineNumberWidth,
                            isSelected: selectedLines.contains(line.number),
                            isHighlighted: line.isHighlighted
                        )
                    }
                    .contentShape(Rectangle())  // Make entire area tappable
                    .onTapGesture {
                        print("Tapped line \(line.number)")
                        toggleSelection(line.number)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
    
    private func toggleSelection(_ lineNumber: Int) {
        if selectedLines.contains(lineNumber) {
            selectedLines.remove(lineNumber)
            print("Removed line \(lineNumber)")
        } else {
            selectedLines.insert(lineNumber)
            print("Added line \(lineNumber)")
        }
        print("Selected lines: \(selectedLines)")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedLines: Set<Int> = [1]
        
        var body: some View {
            DebugCodeViewer(
                lines: [
                    CodeLine(
                        number: 1,
                        content: "func example() {",
                        syntaxTokens: SyntaxParser.parse("func example() {")
                    ),
                    CodeLine(
                        number: 2,
                        content: "    let x = 42",
                        syntaxTokens: SyntaxParser.parse("    let x = 42"),
                        isHighlighted: true,
                        sideComment: "This is a comment"
                    )
                ],
                selectedLines: $selectedLines
            )
        }
    }
    
    return PreviewWrapper()
} 