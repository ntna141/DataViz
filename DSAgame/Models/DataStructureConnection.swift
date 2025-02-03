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
    let scale: CGFloat
    
    struct ConnectionVisualStyle {
        let strokeColor: Color
        let strokeWidth: CGFloat
        let isDashed: Bool
        
        static func standard(scale: CGFloat) -> ConnectionVisualStyle {
            ConnectionVisualStyle(
                strokeColor: .blue,
                strokeWidth: 2 * scale,
                isDashed: false
            )
        }
        
        static func highlighted(scale: CGFloat) -> ConnectionVisualStyle {
            ConnectionVisualStyle(
                strokeColor: .yellow,
                strokeWidth: 3 * scale,
                isDashed: false
            )
        }
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
            visualStyle: isHighlighted ? .highlighted(scale: 1) : .standard(scale: 1),
            scale: 1
        )
    }
}

// View for rendering a connection
struct ConnectionView: View {
    let state: ConnectionDisplayState
    
    var body: some View {
        let adjustedPoints = calculateEdgePoints()
        ZStack {
            // Connection line
            switch state.style {
            case .straight:
                StraightConnectionShape(from: adjustedPoints.from, to: adjustedPoints.to)
                    .stroke(
                        state.visualStyle.strokeColor,
                        style: StrokeStyle(
                            lineWidth: state.visualStyle.strokeWidth,
                            dash: state.visualStyle.isDashed ? [5] : []
                        )
                    )
                
            case .curved:
                CurvedConnectionShape(from: adjustedPoints.from, to: adjustedPoints.to)
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
            
            // Arrow head with scaling
            if state.style != .selfPointing {
                ArrowHead(
                    from: adjustedPoints.from,
                    to: adjustedPoints.to,
                    scale: state.scale
                )
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
                    .position(calculateLabelPosition(from: adjustedPoints.from, to: adjustedPoints.to))
            }
        }
    }
    
    private func calculateEdgePoints() -> (from: CGPoint, to: CGPoint) {
        let cellSize = 40.0 * state.scale // Base cell size * scale
        let angle = atan2(state.fromPoint.y - state.toPoint.y, state.fromPoint.x - state.toPoint.x)  // Reverse angle calculation
        
        // Calculate the points where the line intersects with the cell edges
        let fromPoint = CGPoint(
            x: state.fromPoint.x - cos(angle) * (cellSize / 2),  // Change to minus
            y: state.fromPoint.y - sin(angle) * (cellSize / 2)   // Change to minus
        )
        
        let toPoint = CGPoint(
            x: state.toPoint.x + cos(angle) * (cellSize / 2),    // Change to plus
            y: state.toPoint.y + sin(angle) * (cellSize / 2)     // Change to plus
        )
        
        return (from: fromPoint, to: toPoint)
    }
    
    private func calculateLabelPosition(from: CGPoint, to: CGPoint) -> CGPoint {
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
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
    let scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let angle = atan2(from.y - to.y, from.x - to.x)
        let arrowLength: CGFloat = 10 * scale
        let arrowAngle: CGFloat = .pi / 6
        
        let point1 = CGPoint(
            x: from.x - arrowLength * cos(angle - arrowAngle),
            y: from.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let point2 = CGPoint(
            x: from.x - arrowLength * cos(angle + arrowAngle),
            y: from.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: from)
        path.addLine(to: point1)
        path.addLine(to: point2)
        path.closeSubpath()
        
        return path
    }
} 