import SwiftUI

// Protocol defining the core behavior of a connection between cells
protocol DataStructureConnection: Identifiable {
    var id: String { get }
    var fromCellId: String { get }
    var toCellId: String { get }
    var label: String? { get set }
    var isHighlighted: Bool { get set }
    var style: ConnectionStyle { get set }
    
    // Core connection behaviors
    mutating func highlight()
    mutating func unhighlight()
    mutating func setLabel(_ label: String?)
    mutating func setStyle(_ style: ConnectionStyle)
    
    // Visual state
    var displayState: ConnectionDisplayState { get }
}

// Style options for connections
enum ConnectionStyle: String {
    case straight = "straight"
    case curved = "curved"
    case selfPointing = "selfPointing"
}

// Represents the visual state of a connection
struct ConnectionDisplayState {
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let label: String?
    let isHighlighted: Bool
    let style: ConnectionStyle
    let visualStyle: ConnectionVisualStyle
    
    struct ConnectionVisualStyle {
        let strokeColor: Color
        let strokeWidth: CGFloat
        let isDashed: Bool
        
        static let standard = ConnectionVisualStyle(
            strokeColor: .blue,
            strokeWidth: 2,
            isDashed: false
        )
        
        static let highlighted = ConnectionVisualStyle(
            strokeColor: .yellow,
            strokeWidth: 3,
            isDashed: false
        )
    }
}

// Base implementation of a connection
struct BasicConnection: DataStructureConnection {
    let id: String
    let fromCellId: String
    let toCellId: String
    var label: String?
    var isHighlighted: Bool
    var style: ConnectionStyle
    
    init(
        id: String = UUID().uuidString,
        fromCellId: String,
        toCellId: String,
        label: String? = nil,
        isHighlighted: Bool = false,
        style: ConnectionStyle = .straight
    ) {
        self.id = id
        self.fromCellId = fromCellId
        self.toCellId = toCellId
        self.label = label
        self.isHighlighted = isHighlighted
        self.style = style
    }
    
    // MARK: - Connection Behaviors
    
    mutating func highlight() {
        isHighlighted = true
    }
    
    mutating func unhighlight() {
        isHighlighted = false
    }
    
    mutating func setLabel(_ label: String?) {
        self.label = label
    }
    
    mutating func setStyle(_ style: ConnectionStyle) {
        self.style = style
    }
    
    // MARK: - Display State
    
    var displayState: ConnectionDisplayState {
        // Note: Actual points will be provided by the layout manager
        ConnectionDisplayState(
            fromPoint: .zero,
            toPoint: .zero,
            label: label,
            isHighlighted: isHighlighted,
            style: style,
            visualStyle: isHighlighted ? .highlighted : .standard
        )
    }
}

// View for rendering a connection
struct ConnectionView: View {
    let state: ConnectionDisplayState
    
    var body: some View {
        ZStack {
            // Connection line
            switch state.style {
            case .straight:
                StraightConnectionShape(from: state.fromPoint, to: state.toPoint)
                    .stroke(
                        state.visualStyle.strokeColor,
                        style: StrokeStyle(
                            lineWidth: state.visualStyle.strokeWidth,
                            dash: state.visualStyle.isDashed ? [5] : []
                        )
                    )
                
            case .curved:
                CurvedConnectionShape(from: state.fromPoint, to: state.toPoint)
                    .stroke(
                        state.visualStyle.strokeColor,
                        style: StrokeStyle(
                            lineWidth: state.visualStyle.strokeWidth,
                            dash: state.visualStyle.isDashed ? [5] : []
                        )
                    )
                
            case .selfPointing:
                SelfPointingConnectionShape(at: state.fromPoint)
                    .stroke(
                        state.visualStyle.strokeColor,
                        style: StrokeStyle(
                            lineWidth: state.visualStyle.strokeWidth,
                            dash: state.visualStyle.isDashed ? [5] : []
                        )
                    )
            }
            
            // Arrow head
            if state.style != .selfPointing {
                ArrowHead(from: state.fromPoint, to: state.toPoint)
                    .fill(state.visualStyle.strokeColor)
            }
            
            // Optional label
            if let label = state.label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .position(calculateLabelPosition())
            }
        }
    }
    
    private func calculateLabelPosition() -> CGPoint {
        let midX = (state.fromPoint.x + state.toPoint.x) / 2
        let midY = (state.fromPoint.y + state.toPoint.y) / 2
        return CGPoint(x: midX, y: midY - 15) // Offset above the line
    }
}

// Helper shapes for different connection styles
struct StraightConnectionShape: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

struct CurvedConnectionShape: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        
        let control1 = CGPoint(
            x: from.x + (to.x - from.x) * 0.5,
            y: from.y
        )
        let control2 = CGPoint(
            x: to.x - (to.x - from.x) * 0.5,
            y: to.y
        )
        
        path.addCurve(to: to, control1: control1, control2: control2)
        return path
    }
}

struct SelfPointingConnectionShape: Shape {
    let at: CGPoint
    let radius: CGFloat = 20
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: at.x + radius, y: at.y - radius)
        path.addArc(center: center,
                   radius: radius,
                   startAngle: .degrees(90),
                   endAngle: .degrees(360),
                   clockwise: true)
        return path
    }
}

struct ArrowHead: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10
        let arrowAngle: CGFloat = .pi / 6
        
        let point1 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let point2 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: to)
        path.addLine(to: point1)
        path.addLine(to: point2)
        path.closeSubpath()
        
        return path
    }
} 