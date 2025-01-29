import SwiftUI

// Protocol defining the core behavior of a data structure cell
protocol DataStructureCell: Identifiable {
    var id: String { get }
    var value: String { get set }
    var position: CGPoint { get set }
    var isHighlighted: Bool { get set }
    var label: String? { get set }
    
    // Core cell behaviors
    mutating func setValue(_ value: String)
    mutating func highlight()
    mutating func unhighlight()
    mutating func setHighlighted(_ highlighted: Bool)
    mutating func setLabel(_ label: String?)
    
    // Visual state
    var displayState: CellDisplayState { get }
}

// Represents the visual state of a cell
struct CellDisplayState {
    let value: String
    let isHighlighted: Bool
    let isHovered: Bool
    let label: String?
    let position: CGPoint
    let style: CellStyle
    
    struct CellStyle {
        let fillColor: Color
        let strokeColor: Color
        let strokeWidth: CGFloat
        let isDashed: Bool
        let glowRadius: CGFloat
        let font: Font
        let shadowRadius: CGFloat
        
        static let standard = CellStyle(
            fillColor: Color(red: 0.96, green: 0.95, blue: 0.91),
            strokeColor: Color(red: 0.2, green: 0.2, blue: 0.2),
            strokeWidth: 3.6,
            isDashed: false,
            glowRadius: 0,
            font: .system(.body, design: .rounded).weight(.bold).monospaced(),
            shadowRadius: 12
        )
        
        static let highlighted = CellStyle(
            fillColor: Color(red: 1.5, green: 0.8, blue: 0.8),
            strokeColor: .red,
            strokeWidth: 3.6,
            isDashed: false,
            glowRadius: 4,
            font: .system(.body, design: .rounded).weight(.bold).monospaced(),
            shadowRadius: 14
        )
        
        static let readyToDrop = CellStyle(
            fillColor: Color(red: 1.0, green: 0.9, blue: 0.9),
            strokeColor: .red,
            strokeWidth: 3.6,
            isDashed: false,
            glowRadius: 8,
            font: .system(.body, design: .rounded).weight(.bold).monospaced(),
            shadowRadius: 14
        )
        
        static let empty = CellStyle(
            fillColor: Color(red: 0.98, green: 0.97, blue: 0.95),
            strokeColor: Color(red: 0.7, green: 0.7, blue: 0.7),
            strokeWidth: 2.7,
            isDashed: true,
            glowRadius: 0,
            font: .system(.body, design: .rounded).weight(.bold).monospaced(),
            shadowRadius: 10
        )
        
        static let hovered = CellStyle(
            fillColor: Color(red: 0.93, green: 0.92, blue: 0.88),
            strokeColor: Color(red: 0.2, green: 0.2, blue: 0.2),
            strokeWidth: 3.6,
            isDashed: false,
            glowRadius: 6,
            font: .system(.body, design: .rounded).weight(.bold).monospaced(),
            shadowRadius: 16
        )
    }
}

// Base implementation of a data structure cell
struct BasicCell: DataStructureCell {
    let id: String
    var value: String
    var position: CGPoint
    var isHighlighted: Bool
    var label: String?
    
    init(
        id: String = UUID().uuidString,
        value: String = "",
        position: CGPoint = .zero,
        isHighlighted: Bool = false,
        label: String? = nil
    ) {
        self.id = id
        self.value = value
        self.position = position
        self.isHighlighted = isHighlighted
        self.label = label
    }
    
    // MARK: - Cell Behaviors
    
    mutating func setValue(_ value: String) {
        self.value = value
    }
    
    mutating func highlight() {
        isHighlighted = true
    }
    
    mutating func unhighlight() {
        isHighlighted = false
    }
    
    mutating func setHighlighted(_ highlighted: Bool) {
        isHighlighted = highlighted
    }
    
    mutating func setLabel(_ label: String?) {
        self.label = label
    }
    
    // MARK: - Display State
    
    var displayState: CellDisplayState {
        CellDisplayState(
            value: value,
            isHighlighted: isHighlighted,
            isHovered: false,
            label: label,
            position: position,
            style: determineStyle()
        )
    }
    
    private func determineStyle() -> CellDisplayState.CellStyle {
        if isHighlighted && value.isEmpty {
            return .readyToDrop
        } else if isHighlighted {
            return .highlighted
        } else if value.isEmpty {
            return .empty
        } else {
            return .standard
        }
    }
} 