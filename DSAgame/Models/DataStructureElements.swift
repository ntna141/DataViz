import SwiftUI

// Basic node that can be used in any data structure
struct DSNode: Identifiable, Equatable {
    let id: UUID = UUID()
    var value: String
    var isHighlighted: Bool = false
    var label: String? = nil
    var position: CGPoint = .zero
    
    static func == (lhs: DSNode, rhs: DSNode) -> Bool {
        lhs.value == rhs.value &&
        lhs.isHighlighted == rhs.isHighlighted &&
        lhs.label == rhs.label &&
        abs(lhs.position.x - rhs.position.x) < 1 &&  // Using small threshold for float comparison
        abs(lhs.position.y - rhs.position.y) < 1
    }
}

// Represents a connection between nodes
struct DSConnection: Identifiable, Equatable {
    let id: UUID = UUID()
    let from: UUID
    let to: UUID
    var label: String? = nil
    var isSelfPointing: Bool = false
    var isHighlighted: Bool = false
    var style: ConnectionStyle = .straight
    
    enum ConnectionStyle: String, Equatable {
        case straight = "straight"
        case curved = "curved"
        case selfPointing = "selfPointing"
    }
    
    static func == (lhs: DSConnection, rhs: DSConnection) -> Bool {
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.label == rhs.label &&
        lhs.isSelfPointing == rhs.isSelfPointing &&
        lhs.isHighlighted == rhs.isHighlighted &&
        lhs.style == rhs.style
    }
}

// Visual representation of a node
struct NodeView: View {
    let node: DSNode
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Node background
            Circle()
                .fill(node.isHighlighted ? Color.yellow.opacity(0.3) : Color.white)
                .overlay(
                    Circle()
                        .stroke(node.isHighlighted ? Color.yellow : Color.blue, lineWidth: 2)
                )
                .frame(width: size, height: size)
                .shadow(radius: 2)
            
            // Node value
            Text(node.value)
                .font(.system(size: size * 0.4))
                .foregroundColor(.black)
            
            // Optional label above node
            if let label = node.label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .offset(y: -size * 0.8)
            }
        }
    }
}

// Visual representation of a connection
struct ConnectionView: View {
    let connection: DSConnection
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let nodeSize: CGFloat
    
    var body: some View {
        ZStack {
            // Connection line
            Path { path in
                switch connection.style {
                case .straight:
                    path.move(to: fromPoint)
                    path.addLine(to: toPoint)
                case .curved:
                    let control = CGPoint(
                        x: (fromPoint.x + toPoint.x) / 2,
                        y: min(fromPoint.y, toPoint.y) - 50
                    )
                    path.move(to: fromPoint)
                    path.addQuadCurve(to: toPoint, control: control)
                case .selfPointing:
                    let controlPoint1 = CGPoint(
                        x: fromPoint.x + nodeSize,
                        y: fromPoint.y - nodeSize
                    )
                    let controlPoint2 = CGPoint(
                        x: fromPoint.x - nodeSize,
                        y: fromPoint.y - nodeSize
                    )
                    path.move(to: fromPoint)
                    path.addCurve(
                        to: fromPoint,
                        control1: controlPoint1,
                        control2: controlPoint2
                    )
                }
            }
            .stroke(
                connection.isHighlighted ? Color.yellow : Color.blue,
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: connection.style == .selfPointing ? [5, 5] : []
                )
            )
            
            // Arrow head
            if connection.style != .selfPointing {
                ArrowHead(from: fromPoint, to: toPoint)
                    .fill(connection.isHighlighted ? Color.yellow : Color.blue)
                    .frame(width: 10, height: 10)
            }
            
            // Optional connection label
            if let label = connection.label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .position(
                        x: (fromPoint.x + toPoint.x) / 2,
                        y: (fromPoint.y + toPoint.y) / 2 - 15
                    )
            }
        }
    }
}

// Helper shape for drawing arrow heads
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

// Container view for data structure visualization
struct DataStructureView: View {
    let nodes: [DSNode]
    let connections: [DSConnection]
    let nodeSize: CGFloat = 60
    
    var body: some View {
        ZStack {
            // Draw all connections first
            ForEach(connections) { connection in
                if let fromNode = nodes.first(where: { $0.id == connection.from }),
                   let toNode = nodes.first(where: { $0.id == connection.to }) {
                    ConnectionView(
                        connection: connection,
                        fromPoint: fromNode.position,
                        toPoint: toNode.position,
                        nodeSize: nodeSize
                    )
                }
            }
            
            // Draw all nodes on top
            ForEach(nodes) { node in
                NodeView(node: node, size: nodeSize)
                    .position(node.position)
            }
        }
    }
} 