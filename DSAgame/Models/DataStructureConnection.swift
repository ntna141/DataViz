import SwiftUI


protocol DataStructureConnection: Identifiable {
    var id: String { get }
    var fromCellId: String { get }
    var toCellId: String { get }
    var fromLabel: String? { get set }
    var toLabel: String? { get set }
    var label: String? { get set }
    var isHighlighted: Bool { get set }
    var style: ConnectionStyle { get set }
    
    
    mutating func highlight()
    mutating func unhighlight()
    mutating func setLabel(_ label: String?)
    mutating func setStyle(_ style: ConnectionStyle)
    
    
    var displayState: ConnectionDisplayState { get }
}


enum ConnectionStyle: String, Codable {
    case straight = "straight"
    case curved = "curved"
    case selfPointing = "selfPointing"
}


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


struct ConnectionDisplayState {
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let label: String?
    let isHighlighted: Bool
    let style: ConnectionStyle
    let visualStyle: ConnectionVisualStyle
    let scale: CGFloat
    let isBinaryTree: Bool
    
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
        
        
        let connectionData = try ConnectionData(from: decoder)
        
        
        if let fromIndex = connectionData.from, let toIndex = connectionData.to {
            
            fromCellId = "node_\(fromIndex)"
            toCellId = "node_\(toIndex)"
        } else {
            
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
    
    
    
    var displayState: ConnectionDisplayState {
        _displayState ?? ConnectionDisplayState(
            fromPoint: .zero,
            toPoint: .zero,
            label: label,
            isHighlighted: isHighlighted,
            style: style,
            visualStyle: isHighlighted ? .highlighted(scale: 1) : .standard(scale: 1),
            scale: 1,
            isBinaryTree: false
        )
    }
}


struct ConnectionView: View {
    let state: ConnectionDisplayState
    
    var body: some View {
        let adjustedPoints = calculateEdgePoints()
        ZStack {
            
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
            
            
            if state.style != .selfPointing {
                ArrowHead(
                    from: adjustedPoints.from,
                    to: adjustedPoints.to,
                    scale: state.scale
                )
                    .fill(state.visualStyle.strokeColor)
            }
            
            
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
        let cellSize = 40.0 * state.scale
        
        
        let dx = state.toPoint.x - state.fromPoint.x
        let dy = state.toPoint.y - state.fromPoint.y
        
        if state.isBinaryTree {
            
            
            let fromPoint = CGPoint(
                x: state.fromPoint.x + dx * 0.3,
                y: state.fromPoint.y + dy * 0.3
            )
            
            let toPoint = CGPoint(
                x: state.toPoint.x - dx * 0.3,
                y: state.toPoint.y - dy * 0.3
            )
            
            return (from: toPoint, to: fromPoint)
        } else {
            
            let angle = atan2(dy, dx)
            
            
            let isDifferentRows = abs(dy) > cellSize / 2
            
            
            let baseOffset = cellSize / 2 * 1.2
            
            let adjustedOffset = if isDifferentRows {
                
                baseOffset * 1.9
            } else {
                
                baseOffset
            }
            
            
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
    }
    
    private func calculateLabelPosition(from: CGPoint, to: CGPoint) -> CGPoint {
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        return CGPoint(x: midX, y: midY - 5) 
    }
}


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
        
        
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10 * scale
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

