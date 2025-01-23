import SwiftUI

// Layout manager for different data structure types
enum DataStructureLayoutManager {
    static let nodeRadius: CGFloat = 24
    static let horizontalSpacing: CGFloat = 30
    static let verticalSpacing: CGFloat = 30
    
    static func calculateLinkedListLayout(nodes: [DSNode], in frame: CGRect) -> [DSNode] {
        guard !nodes.isEmpty else { return [] }
        
        // Calculate total width needed for all nodes
        let nodeWidth = nodeRadius * 2
        let totalWidth = CGFloat(nodes.count) * nodeWidth + CGFloat(nodes.count - 1) * horizontalSpacing
        
        // Calculate starting X position to center the list horizontally
        let startX = (frame.width - totalWidth) / 2 + nodeRadius
        let centerY = frame.height / 2
        
        return nodes.enumerated().map { index, node in
            var newNode = node
            newNode.position = CGPoint(
                x: startX + CGFloat(index) * (nodeWidth + horizontalSpacing),
                y: centerY
            )
            return newNode
        }
    }
    
    static func calculateBinaryTreeLayout(nodes: [DSNode], in frame: CGRect) -> [DSNode] {
        guard !nodes.isEmpty else { return [] }
        
        let levels = Int(log2(Double(nodes.count))) + 1
        let nodeWidth = nodeRadius * 2
        let totalHeight = CGFloat(levels - 1) * (nodeWidth + verticalSpacing)
        let startY = (frame.height - totalHeight) / 2 + nodeRadius
        
        return nodes.enumerated().map { index, node in
            var newNode = node
            let level = Int(floor(log2(Double(index + 1))))
            let nodesInLevel = pow(2.0, Double(level))
            let position = Double(index + 1) - pow(2.0, Double(level))
            
            // Calculate horizontal spacing for this level
            let levelWidth = nodesInLevel * Double(nodeWidth) + (nodesInLevel - 1) * Double(horizontalSpacing)
            let levelStartX = (Double(frame.width) - levelWidth) / 2 + Double(nodeRadius)
            let x = levelStartX + position * (Double(nodeWidth) + Double(horizontalSpacing))
            
            newNode.position = CGPoint(
                x: x,
                y: startY + CGFloat(level) * (nodeWidth + verticalSpacing)
            )
            return newNode
        }
    }
    
    static func calculateArrayLayout(nodes: [DSNode], in frame: CGRect) -> [DSNode] {
        // Similar to linked list but with different spacing and no arrows
        guard !nodes.isEmpty else { return [] }
        
        let nodeWidth = nodeRadius * 2
        let totalWidth = CGFloat(nodes.count) * nodeWidth + CGFloat(nodes.count - 1) * horizontalSpacing
        let startX = (frame.width - totalWidth) / 2 + nodeRadius
        let centerY = frame.height / 2
        
        return nodes.enumerated().map { index, node in
            var newNode = node
            newNode.position = CGPoint(
                x: startX + CGFloat(index) * (nodeWidth + horizontalSpacing),
                y: centerY
            )
            return newNode
        }
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
    let isDropTarget: Bool
    
    var body: some View {
        ZStack {
            // Node background
            Circle()
                .fill(node.isHighlighted ? Color.yellow.opacity(0.3) : Color.white)
                .overlay(
                    Circle()
                        .stroke(
                            node.value.isEmpty ? (isDropTarget ? Color.green : Color.gray) : (node.isHighlighted ? Color.yellow : Color.blue),
                            style: StrokeStyle(
                                lineWidth: isDropTarget ? 3 : 2,
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
                    .foregroundColor(isDropTarget ? Color.green : Color.gray)
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
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .offset(y: -size * 0.8)
            }
        }
        .scaleEffect(isDropTarget ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isDropTarget)
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
                        y: min(fromPoint.y, toPoint.y) - DataStructureLayoutManager.verticalSpacing
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
                let arrowLength: CGFloat = DataStructureLayoutManager.nodeRadius * 0.25
                let arrowAngle: CGFloat = .pi / 6 // 30 degrees
                
                Path { path in
                    path.move(to: toPoint)
                    path.addLine(to: CGPoint(
                        x: toPoint.x - arrowLength * cos(angle - arrowAngle),
                        y: toPoint.y - arrowLength * sin(angle - arrowAngle)
                    ))
                    path.move(to: toPoint)
                    path.addLine(to: CGPoint(
                        x: toPoint.x - arrowLength * cos(angle + arrowAngle),
                        y: toPoint.y - arrowLength * sin(angle + arrowAngle)
                    ))
                }
                .stroke(
                    connection.isHighlighted ? Color.yellow : Color.blue,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
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
    enum LayoutType: String {
        case linkedList = "linkedList"
        case binaryTree = "binaryTree"
        case array = "array"
    }
    
    let nodes: [DSNode]
    let connections: [DSConnection]
    let nodeSize: CGFloat = DataStructureLayoutManager.nodeRadius * 2
    let layoutType: LayoutType
    let targetNodeIndex: Int?
    @State private var frame: CGRect = .zero
    @State private var layoutNodes: [DSNode] = []
    
    init(nodes: [DSNode], connections: [DSConnection], layoutType: LayoutType = .linkedList, targetNodeIndex: Int? = nil) {
        self.nodes = nodes
        self.connections = connections
        self.layoutType = layoutType
        self.targetNodeIndex = targetNodeIndex
        print("DataStructureView init - Target node index: \(String(describing: targetNodeIndex))")
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
                            toPoint: calculateEndpoint(from: fromNode.position, to: toNode.position),
                            nodeSize: nodeSize
                        )
                    }
                }
                
                // Draw all nodes on top
                ForEach(Array(layoutNodes.enumerated()), id: \.element.id) { index, node in
                    NodeView(
                        node: node,
                        size: nodeSize,
                        isDropTarget: index == targetNodeIndex && node.value.isEmpty
                    )
                    .position(node.position)
                }
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            print("Frame changed: \(newFrame)")
            frame = newFrame
            updateLayout()
        }
        .onChange(of: nodes) { newNodes in
            print("Nodes changed - Count: \(newNodes.count)")
            updateLayout()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func updateLayout() {
        guard !frame.isEmpty else { return }
        print("Updating layout - Frame: \(frame)")
        
        switch layoutType {
        case .linkedList:
            layoutNodes = DataStructureLayoutManager.calculateLinkedListLayout(nodes: nodes, in: frame)
        case .binaryTree:
            layoutNodes = DataStructureLayoutManager.calculateBinaryTreeLayout(nodes: nodes, in: frame)
        case .array:
            layoutNodes = DataStructureLayoutManager.calculateArrayLayout(nodes: nodes, in: frame)
        }
        print("Layout updated - Node positions: \(layoutNodes.map { $0.position })")
    }
    
    private func calculateEndpoint(from: CGPoint, to: CGPoint) -> CGPoint {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let radius = DataStructureLayoutManager.nodeRadius
        
        return CGPoint(
            x: to.x - radius * cos(angle),
            y: to.y - radius * sin(angle)
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