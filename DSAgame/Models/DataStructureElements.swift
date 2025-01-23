import SwiftUI

// Layout manager for different data structure types
enum DataStructureLayoutManager {
    static let nodeRadius: CGFloat = 40
    static let horizontalSpacing: CGFloat = 50
    static let verticalSpacing: CGFloat = 50
    
    static func calculateLinkedListLayout(nodes: [DSNode], in frame: CGRect) -> [DSNode] {
        guard !nodes.isEmpty else { return [] }
        
        let totalWidth = CGFloat(nodes.count - 1) * (nodeRadius * 2 + horizontalSpacing)
        let startX = (frame.width - totalWidth) / 2
        let centerY = frame.height / 2
        
        return nodes.enumerated().map { index, node in
            var newNode = node
            newNode.position = CGPoint(
                x: startX + CGFloat(index) * (nodeRadius * 2 + horizontalSpacing) + nodeRadius,
                y: centerY
            )
            return newNode
        }
    }
    
    static func calculateBinaryTreeLayout(nodes: [DSNode], in frame: CGRect) -> [DSNode] {
        guard !nodes.isEmpty else { return [] }
        
        let levels = Int(log2(Double(nodes.count))) + 1
        let totalHeight = CGFloat(levels - 1) * (nodeRadius * 2 + verticalSpacing)
        let startY = (frame.height - totalHeight) / 2
        
        return nodes.enumerated().map { index, node in
            var newNode = node
            let level = Int(floor(log2(Double(index + 1))))
            let nodesInLevel = pow(2.0, Double(level))
            let position = Double(index + 1) - pow(2.0, Double(level))
            let spacing = frame.width / (nodesInLevel + 1)
            
            newNode.position = CGPoint(
                x: spacing * (position + 1),
                y: startY + CGFloat(level) * (nodeRadius * 2 + verticalSpacing)
            )
            return newNode
        }
    }
    
    static func calculateArrayLayout(nodes: [DSNode], in frame: CGRect) -> [DSNode] {
        // Similar to linked list but with different spacing and no arrows
        return calculateLinkedListLayout(nodes: nodes, in: frame)
    }
}

// Basic node that can be used in any data structure
struct DSNode: Identifiable, Equatable {
    let id: UUID
    var value: String
    var isHighlighted: Bool = false
    var label: String? = nil
    var position: CGPoint = .zero
    
    init(id: UUID = UUID(), value: String, isHighlighted: Bool = false, label: String? = nil, position: CGPoint = .zero) {
        self.id = id
        self.value = value
        self.isHighlighted = isHighlighted
        self.label = label
        self.position = position
    }
    
    static func == (lhs: DSNode, rhs: DSNode) -> Bool {
        lhs.id == rhs.id &&
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
                        .stroke(
                            node.value.isEmpty ? Color.gray : (node.isHighlighted ? Color.yellow : Color.blue),
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: node.value.isEmpty ? [5] : []
                            )
                        )
                )
                .frame(width: size, height: size)
                .shadow(radius: 2)
            
            // Node value or placeholder
            if node.value.isEmpty {
                Text("?")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.gray)
            } else {
                Text(node.value)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.black)
            }
            
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
                let angle = atan2(toPoint.y - fromPoint.y, toPoint.x - fromPoint.x)
                let arrowLength: CGFloat = 10
                let arrowAngle: CGFloat = .pi / 6 // 30 degrees
                
                let arrowPoint = CGPoint(
                    x: toPoint.x - (nodeSize/2) * cos(angle),
                    y: toPoint.y - (nodeSize/2) * sin(angle)
                )
                
                Path { path in
                    path.move(to: arrowPoint)
                    path.addLine(to: CGPoint(
                        x: arrowPoint.x - arrowLength * cos(angle - arrowAngle),
                        y: arrowPoint.y - arrowLength * sin(angle - arrowAngle)
                    ))
                    path.move(to: arrowPoint)
                    path.addLine(to: CGPoint(
                        x: arrowPoint.x - arrowLength * cos(angle + arrowAngle),
                        y: arrowPoint.y - arrowLength * sin(angle + arrowAngle)
                    ))
                }
                .stroke(
                    connection.isHighlighted ? Color.yellow : Color.blue,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            
            // Optional connection label
            if let label = connection.label {
                let midPoint = CGPoint(
                    x: (fromPoint.x + toPoint.x) / 2,
                    y: (fromPoint.y + toPoint.y) / 2 - 15
                )
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .position(midPoint)
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
    enum LayoutType: String {
        case linkedList = "linkedList"
        case binaryTree = "binaryTree"
        case array = "array"
    }
    
    let nodes: [DSNode]
    let connections: [DSConnection]
    let nodeSize: CGFloat = DataStructureLayoutManager.nodeRadius * 2
    let layoutType: LayoutType
    @State private var frame: CGRect = .zero
    @State private var layoutNodes: [DSNode] = []
    
    init(nodes: [DSNode], connections: [DSConnection], layoutType: LayoutType = .linkedList) {
        self.nodes = nodes
        self.connections = connections
        self.layoutType = layoutType
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear.preference(key: FramePreferenceKey.self, value: geometry.frame(in: .local))
                
                // Draw all connections first
                ForEach(connections) { connection in
                    if let fromNode = layoutNodes.first(where: { $0.id == connection.from }),
                       let toNode = layoutNodes.first(where: { $0.id == connection.to }) {
                        ConnectionView(
                            connection: connection,
                            fromPoint: fromNode.position,
                            toPoint: toPoint(from: fromNode.position, to: toNode.position, nodeSize: nodeSize),
                            nodeSize: nodeSize
                        )
                    }
                }
                
                // Draw all nodes on top
                ForEach(layoutNodes) { node in
                    NodeView(node: node, size: nodeSize)
                        .position(node.position)
                }
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            frame = newFrame
            updateLayout()
        }
        .onChange(of: nodes) { _ in
            updateLayout()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func updateLayout() {
        guard !frame.isEmpty else { return }
        
        switch layoutType {
        case .linkedList:
            layoutNodes = DataStructureLayoutManager.calculateLinkedListLayout(nodes: nodes, in: frame)
        case .binaryTree:
            layoutNodes = DataStructureLayoutManager.calculateBinaryTreeLayout(nodes: nodes, in: frame)
        case .array:
            layoutNodes = DataStructureLayoutManager.calculateArrayLayout(nodes: nodes, in: frame)
        }
    }
    
    private func toPoint(from: CGPoint, to: CGPoint, nodeSize: CGFloat) -> CGPoint {
        let angle = atan2(to.y - from.y, to.x - from.x)
        return CGPoint(
            x: to.x - (nodeSize/2) * cos(angle),
            y: to.y - (nodeSize/2) * sin(angle)
        )
    }
}

// Helper for getting frame size
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
} 