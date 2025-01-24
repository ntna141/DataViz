import SwiftUI

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

// Helper extension for CGRect
extension CGRect {
    func convert(from globalPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: globalPoint.x - origin.x,
            y: globalPoint.y - origin.y
        )
    }
}

struct DataStructureView: View {
    let layoutType: DataStructureLayoutType
    let cells: [any DataStructureCell]
    let connections: [any DataStructureConnection]
    let availableElements: [String]
    let onElementDropped: (String, Int) -> Void
    
    @State private var frame: CGRect = .zero
    @State private var layoutManager: DataStructureLayoutManager
    @State private var layoutCells: [any DataStructureCell] = []
    @State private var connectionStates: [(id: String, state: ConnectionDisplayState)] = []
    @State private var dragState: (element: String, location: CGPoint)?
    @State private var hoveredCellIndex: Int?
    @State private var renderCycle = UUID()
    
    init(
        layoutType: DataStructureLayoutType,
        cells: [any DataStructureCell],
        connections: [any DataStructureConnection],
        availableElements: [String] = [],
        onElementDropped: @escaping (String, Int) -> Void = { _, _ in }
    ) {
        self.layoutType = layoutType
        self.cells = cells
        self.connections = connections
        self.availableElements = availableElements
        self.onElementDropped = onElementDropped
        self._layoutManager = State(initialValue: DataStructureLayoutManager(layoutType: layoutType))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear.preference(key: FramePreferenceKey.self, value: geometry.frame(in: .local))
                
                // Draw all connections first
                ForEach(connectionStates, id: \.id) { connection in
                    ConnectionView(state: connection.state)
                }
                
                // Draw all cells on top with renderCycle for uniqueness
                ForEach(Array(layoutCells.enumerated()), id: \.element.id) { index, cell in
                    CellView(
                        state: cell.displayState,
                        size: LayoutConfig.cellDiameter
                    )
                    .id("\(cell.id)-\(renderCycle)")
                    .position(cell.position)
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { value in
                                handleDragChanged(value, in: geometry.frame(in: .global), cellIndex: index)
                            }
                            .onEnded { value in
                                handleDragEnded(value)
                            }
                    )
                }
                
                // Available elements at the top
                if !availableElements.isEmpty {
                    HStack(spacing: 15) {
                        ForEach(availableElements, id: \.self) { element in
                            if !layoutCells.contains(where: { $0.value == element }) {
                                DraggableElementView(
                                    element: element,
                                    isDragging: dragState?.element == element,
                                    onDragStarted: { location in
                                        let localLocation = geometry.frame(in: .global).convert(from: location)
                                        dragState = (element: element, location: localLocation)
                                    },
                                    onDragChanged: { value in
                                        handleDragChanged(value, in: geometry.frame(in: .global))
                                    },
                                    onDragEnded: handleDragEnded
                                )
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
                    DraggableElementView(
                        element: dragState.element,
                        isDragging: true,
                        onDragStarted: { _ in },
                        onDragChanged: { value in
                            handleDragChanged(value, in: geometry.frame(in: .global))
                        },
                        onDragEnded: handleDragEnded
                    )
                    .position(dragState.location)
                }
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            frame = newFrame
            updateLayout()
        }
        .onChange(of: cells.map(\.id)) { _ in
            updateLayout()
        }
        .onChange(of: connections.map(\.id)) { _ in
            updateLayout()
        }
        .onChange(of: layoutType) { newType in
            layoutManager.setLayoutType(newType)
            updateLayout()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func updateLayout() {
        guard !frame.isEmpty else { return }
        let (newCells, newStates) = layoutManager.updateLayout(
            cells: cells,
            connections: connections,
            in: frame
        )
        layoutCells = newCells
        connectionStates = newStates.enumerated().map { (index, state) in
            (id: "\(index)", state: state)
        }
        renderCycle = UUID()
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, in globalFrame: CGRect, cellIndex: Int? = nil) {
        let localLocation = globalFrame.convert(from: value.location)
        
        if let index = cellIndex, dragState == nil {
            // Start dragging from an existing cell
            dragState = (element: layoutCells[index].value, location: localLocation)
        } else if dragState != nil {
            // Update drag location
            dragState?.location = localLocation
            
            // Find closest cell
            let closestCell = layoutCells.enumerated()
                .min(by: { first, second in
                    let distance1 = distance(from: first.element.position, to: localLocation)
                    let distance2 = distance(from: second.element.position, to: localLocation)
                    return distance1 < distance2
                })
            
            if let closest = closestCell,
               distance(from: closest.element.position, to: localLocation) < LayoutConfig.cellDiameter {
                hoveredCellIndex = closest.offset
            } else {
                hoveredCellIndex = nil
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        if let cellIndex = hoveredCellIndex,
           let element = dragState?.element {
            onElementDropped(element, cellIndex)
        }
        dragState = nil
        hoveredCellIndex = nil
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
}

// Helper for getting frame size
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Preview
struct DataStructureView_Previews: PreviewProvider {
    static var previews: some View {
        let cells: [any DataStructureCell] = [
            BasicCell(value: "1"),
            BasicCell(value: "2"),
            BasicCell(value: "3", label: "head")
        ]
        
        let connections: [any DataStructureConnection] = [
            BasicConnection(fromCellId: cells[0].id, toCellId: cells[1].id),
            BasicConnection(fromCellId: cells[1].id, toCellId: cells[2].id)
        ]
        
        DataStructureView(
            layoutType: .linkedList,
            cells: cells,
            connections: connections,
            availableElements: ["4", "5", "6"]
        )
        .frame(width: 500, height: 300)
        .previewLayout(.sizeThatFits)
    }
} 