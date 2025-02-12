import SwiftUI

// Protocol defining the core behavior of a connection between cells
protocol DataStructureConnection: Identifiable {
    var id: String { get }
    var fromCellId: String { get }
    var toCellId: String { get }
    var fromLabel: String? { get set }
    var toLabel: String? { get set }
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
enum ConnectionStyle: String, Codable {
    case straight = "straight"
    case curved = "curved"
    case selfPointing = "selfPointing"
}

// Helper struct for decoding connections from JSON
struct ConnectionData: Codable {
    let from: Int?
    let to: Int?
    let fromLabel: String?
    let toLabel: String?
    let label: String?
    let isHighlighted: Bool?
    let style: ConnectionStyle?
    
    enum CodingKeys: String, CodingKey {
        case from, to, fromLabel, toLabel, label, isHighlighted, style
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        from = try container.decodeIfPresent(Int.self, forKey: .from)
        to = try container.decodeIfPresent(Int.self, forKey: .to)
        fromLabel = try container.decodeIfPresent(String.self, forKey: .fromLabel)
        toLabel = try container.decodeIfPresent(String.self, forKey: .toLabel)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        isHighlighted = try container.decodeIfPresent(Bool.self, forKey: .isHighlighted)
        style = try container.decodeIfPresent(ConnectionStyle.self, forKey: .style)
    }
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
struct BasicConnection: DataStructureConnection, Codable {
    let id: String
    let fromCellId: String
    let toCellId: String
    var fromLabel: String?
    var toLabel: String?
    var label: String?
    var isHighlighted: Bool
    var style: ConnectionStyle
    private var _displayState: ConnectionDisplayState?
    
    enum CodingKeys: String, CodingKey {
        case id, fromCellId, toCellId, fromLabel, toLabel, label, isHighlighted, style
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        
        // Try to decode connection data
        let connectionData = try ConnectionData(from: decoder)
        
        // Handle both index-based and label-based connections
        if let fromIndex = connectionData.from, let toIndex = connectionData.to {
            // For index-based connections, we'll use placeholder IDs that will be updated later
            fromCellId = "node_\(fromIndex)"
            toCellId = "node_\(toIndex)"
        } else {
            // For label-based connections, use the labels as IDs
            fromCellId = connectionData.fromLabel ?? ""
            toCellId = connectionData.toLabel ?? ""
        }
        
        fromLabel = connectionData.fromLabel
        toLabel = connectionData.toLabel
        label = connectionData.label
        isHighlighted = connectionData.isHighlighted ?? false
        style = connectionData.style ?? .straight
    }
    
    init(
        id: String = UUID().uuidString,
        fromCellId: String,
        toCellId: String,
        fromLabel: String? = nil,
        toLabel: String? = nil,
        label: String? = nil,
        isHighlighted: Bool = false,
        style: ConnectionStyle = .straight
    ) {
        self.id = id
        self.fromCellId = fromCellId
        self.toCellId = toCellId
        self.fromLabel = fromLabel
        self.toLabel = toLabel
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
        _displayState ?? ConnectionDisplayState(
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
        
        // Calculate the distance between points
        let dx = state.toPoint.x - state.fromPoint.x
        let dy = state.toPoint.y - state.fromPoint.y
        
        // Calculate angle from source to target
        let angle = atan2(dy, dx)
        
        // Check if nodes are on different rows
        let isDifferentRows = abs(dy) > cellSize / 2
        
        // Base offset for same-row connections
        let baseOffset = cellSize / 2 * 1.2
        
        let adjustedOffset = if isDifferentRows {
            // For different rows, use much larger offset
            baseOffset * 1.7
        } else {
            // For same row, use normal offset
            baseOffset
        }
        
        // Calculate the points where the line intersects with the cell edges
        let fromPoint = CGPoint(
            x: state.fromPoint.x + cos(angle) * adjustedOffset,
            y: state.fromPoint.y + sin(angle) * adjustedOffset
        )
        
        let toPoint = CGPoint(
            x: state.toPoint.x - cos(angle) * adjustedOffset,
            y: state.toPoint.y - sin(angle) * adjustedOffset
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
        
        // Calculate angle from source to target (not reversed)
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10 * scale
        let arrowAngle: CGFloat = .pi / 6
        
        // Calculate arrow head points relative to the target point
        let point1 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let point2 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )
        
        // Draw arrow head starting from the tip
        path.move(to: to)
        path.addLine(to: point1)
        path.addLine(to: point2)
        path.closeSubpath()
        
        return path
    }
} 