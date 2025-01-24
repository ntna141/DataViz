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
    let snappedElement: String?
    
    // Compute a single value to track state changes for animation
    private var animationState: Int {
        var state = 0
        if isDropTarget { state += 1 }
        if snappedElement != nil { state += 2 }
        return state
    }
    
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
                                dash: node.value.isEmpty && snappedElement == nil ? [5] : []
                            )
                        )
                )
                .frame(width: size, height: size)
                .shadow(radius: 2)
            
            // Node value, snapped element, or placeholder
            if let snappedElement = snappedElement {
                Text(snappedElement)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.black)
            } else if node.value.isEmpty {
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
        .animation(.spring(response: 0.3), value: animationState)
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
    let availableElements: [String]
    let onElementDropped: (String, Int) -> Void
    
    @State private var frame: CGRect = .zero
    @State private var layoutNodes: [DSNode] = []
    @State private var dragState: (element: String, location: CGPoint)?
    @State private var hoveredNodeIndex: Int?
    @State private var snappedElements: [Int: String] = [:] // nodeIndex: element
    
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
                        isDropTarget: index == hoveredNodeIndex && node.value.isEmpty && snappedElements[index] == nil,
                        snappedElement: snappedElements[index]
                    )
                    .position(node.position)
                }
                
                // Available elements at the top
                if !availableElements.isEmpty {
                    HStack(spacing: 15) {
                        ForEach(availableElements, id: \.self) { element in
                            if !snappedElements.values.contains(element) {
                                GeometryReader { elementGeometry in
                                    DraggableElementView(
                                        element: element,
                                        isDragging: dragState?.element == element,
                                        onDragStarted: { globalLocation in
                                            let localLocation = geometry.frame(in: .global).convert(from: globalLocation)
                                            dragState = (element: element, location: localLocation)
                                        },
                                        onDragChanged: { value in
                                            let localLocation = geometry.frame(in: .global).convert(from: value.location)
                                            dragState?.location = localLocation
                                            
                                            // Find closest empty node
                                            let closestNode = layoutNodes.enumerated()
                                                .filter { $0.element.value.isEmpty && snappedElements[$0.offset] == nil }
                                                .min(by: { first, second in
                                                    let distance1 = distance(from: first.element.position, to: localLocation)
                                                    let distance2 = distance(from: second.element.position, to: localLocation)
                                                    return distance1 < distance2
                                                })
                                            
                                            // Update hover state
                                            if let closest = closestNode,
                                               distance(from: closest.element.position, to: localLocation) < nodeSize {
                                                hoveredNodeIndex = closest.offset
                                            } else {
                                                hoveredNodeIndex = nil
                                            }
                                        },
                                        onDragEnded: { value in
                                            if let nodeIndex = hoveredNodeIndex {
                                                snappedElements[nodeIndex] = element
                                                onElementDropped(element, nodeIndex)
                                            }
                                            dragState = nil
                                            hoveredNodeIndex = nil
                                        }
                                    )
                                    .position(x: elementGeometry.size.width/2, y: elementGeometry.size.height/2)
                                }
                                .frame(width: 50, height: 50)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .position(x: geometry.size.width/2, y: 40)
                }
                
                // Dragged element overlay
                if let dragState = dragState {
                    Text(dragState.element)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .scaleEffect(1.1)
                        .position(dragState.location)
                }
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            frame = newFrame
            updateLayout()
        }
        .onChange(of: nodes) { newNodes in
            updateLayout()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func updateLayout() {
        guard !frame.isEmpty else { return }
        
        let newNodes: [DSNode]
        switch layoutType {
        case .linkedList:
            newNodes = DataStructureLayoutManager.calculateLinkedListLayout(nodes: nodes, in: frame)
        case .binaryTree:
            newNodes = DataStructureLayoutManager.calculateBinaryTreeLayout(nodes: nodes, in: frame)
        case .array:
            newNodes = DataStructureLayoutManager.calculateArrayLayout(nodes: nodes, in: frame)
        }
        
        // Print layout positions
        print("\nNode positions after layout calculation:")
        for (index, node) in newNodes.enumerated() {
            print("Node \(index) position: \(node.position)")
        }
        
        layoutNodes = newNodes
    }
    
    private func calculateEndpoint(from: CGPoint, to: CGPoint) -> CGPoint {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let radius = DataStructureLayoutManager.nodeRadius
        
        return CGPoint(
            x: to.x - radius * cos(angle),
            y: to.y - radius * sin(angle)
        )
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
}

extension CGRect {
    func convert(from globalPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: globalPoint.x - origin.x,
            y: globalPoint.y - origin.y
        )
    }
}

// Draggable element view
struct DraggableElementView: View {
    let element: String
    let isDragging: Bool
    let onDragStarted: (CGPoint) -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    var body: some View {
        Text(element)
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: isDragging ? 4 : 2)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(isDragging ? 0.3 : 1.0)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                            // Adjust initial position to account for the offset
                            let adjustedLocation = CGPoint(
                                x: value.location.x,
                                y: value.location.y - 30
                            )
                            onDragStarted(adjustedLocation)
                        }
                        onDragChanged(value)
                    }
                    .onEnded(onDragEnded)
            )
            .animation(.spring(response: 0.3), value: isDragging)
    }
}

// Helper for getting frame size
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
} 