import SwiftUI

struct Cell: Identifiable, Equatable {
    let id: UUID = UUID()
    var value: String
    var position: CGPoint
    var size: CGSize = CGSize(width: 60, height: 60)
    var isHighlighted: Bool = false
    var label: String?
    var labelPosition: LabelPosition = .top
    
    enum LabelPosition {
        case top, bottom, left, right
    }
    
    static func == (lhs: Cell, rhs: Cell) -> Bool {
        lhs.id == rhs.id
    }
}

struct Arrow: Identifiable, Equatable {
    let id: UUID = UUID()
    var from: UUID  // Cell ID
    var to: UUID    // Cell ID
    var style: ArrowStyle = .straight
    var label: String?
    var isHighlighted: Bool = false
    
    enum ArrowStyle {
        case straight
        case curved(controlPoint: CGPoint)
        case dashed
    }
    
    static func == (lhs: Arrow, rhs: Arrow) -> Bool {
        lhs.id == rhs.id
    }
} 