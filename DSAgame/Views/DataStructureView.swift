import SwiftUI

// Draggable element view
struct DraggableElementView: View {
    let element: String
    let isDragging: Bool
    let onDragStarted: (CGPoint) -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    @EnvironmentObject private var cellSizeManager: CellSizeManager
    
    var body: some View {
        Text(element)
            .font(.system(size: cellSizeManager.size * 0.4))
            .frame(width: cellSizeManager.size, height: cellSizeManager.size)
            .background(Color.white)
            .cornerRadius(cellSizeManager.size * 0.1)
            .shadow(radius: isDragging ? 4 : 2)
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .opacity(isDragging ? 0.3 : 1.0)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                            onDragStarted(value.location)
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

// Add this helper view
struct LayoutCellView: View {
    let cell: any DataStructureCell
    let index: Int
    let hoveredCellIndex: Int?
    let cellSize: CGFloat
    let renderCycle: UUID
    let dragState: (element: String, location: CGPoint)?
    let draggingFromCellIndex: Int?
    let onDragChanged: (DragGesture.Value, CGRect) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let geometryFrame: CGRect
    
    var body: some View {
        let isHovered = hoveredCellIndex == index
        let displayState = CellDisplayState(
            value: cell.displayState.value,
            isHighlighted: cell.displayState.isHighlighted,
            isHovered: isHovered,
            label: cell.displayState.label,
            position: cell.position,
            style: isHovered ? .hovered : cell.displayState.style
        )
        
        CellView(state: displayState)
        .id("\(cell.id)-\(renderCycle)")
        .position(cell.position)
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    if !cell.value.isEmpty && dragState == nil {
                        let localLocation = geometryFrame.convert(from: value.location)
                        // First call to set up initial drag state
                        onDragChanged(value, geometryFrame)
                    }
                    // Subsequent calls to update drag position
                    onDragChanged(value, geometryFrame)
                }
                .onEnded(onDragEnded)
        )
    }
}

// Connection layer component
struct ConnectionsLayer: View {
    let connectionStates: [(id: String, state: ConnectionDisplayState)]
    
    var body: some View {
        ForEach(connectionStates, id: \.id) { connection in
            ConnectionView(state: connection.state)
        }
    }
}

// Cells layer component
struct CellsLayer: View {
    let layoutCells: [any DataStructureCell]
    let hoveredCellIndex: Int?
    let cellSize: CGFloat
    let renderCycle: UUID
    let dragState: (element: String, location: CGPoint)?
    let draggingFromCellIndex: Int?
    let geometry: GeometryProxy
    let onDragChanged: (DragGesture.Value, CGRect) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    
    var body: some View {
        let cells = Array(layoutCells.enumerated())
        ForEach(cells, id: \.element.id) { pair in
            let (index, cell) = pair
            createLayoutCell(index: index, cell: cell)
        }
    }
    
    private func createLayoutCell(index: Int, cell: any DataStructureCell) -> some View {
        let frame = geometry.frame(in: .global)
        return LayoutCellView(
            cell: cell,
            index: index,
            hoveredCellIndex: hoveredCellIndex,
            cellSize: cellSize,
            renderCycle: renderCycle,
            dragState: dragState,
            draggingFromCellIndex: draggingFromCellIndex,
            onDragChanged: { value, frame in
                handleDragChange(value: value, frame: frame)
            },
            onDragEnded: onDragEnded,
            geometryFrame: frame
        )
    }
    
    private func handleDragChange(value: DragGesture.Value, frame: CGRect) {
        if dragState == nil {
            // Initialize drag state when starting drag from a cell
            onDragChanged(value, frame)
        }
        // Update drag position
        onDragChanged(value, frame)
    }
}

// Elements list component
struct ElementsListView: View {
    let availableElements: [String]
    let droppedElements: [String]
    let dragState: (element: String, location: CGPoint)?
    let isOverElementList: Bool
    let onDragStarted: (String, CGPoint) -> Void
    let onDragChanged: (DragGesture.Value, CGRect) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let geometryFrame: CGRect
    let cellSize: CGFloat
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellSize * 0.2) {
                let elements = availableElements + droppedElements
                ForEach(elements, id: \.self) { element in
                    createDraggableElement(for: element)
                }
                
                if shouldShowDropHint {
                    createDropHint()
                }
            }
            .padding(cellSize * 0.2)
        }
        .background(listBackground)
        .cornerRadius(cellSize * 0.1)
        .frame(width: calculateListWidth())
        .frame(height: cellSize * 1.5)
        .fixedSize()
    }
    
    private var shouldShowDropHint: Bool {
        availableElements.isEmpty && droppedElements.isEmpty
    }
    
    private var listBackground: some View {
        Color.gray.opacity(isOverElementList ? 0.2 : 0.1)
    }
    
    private func calculateListWidth() -> CGFloat {
        let elements = availableElements + droppedElements
        if elements.isEmpty {
            return cellSize * 3 // Width for "Drop here to remove" text
        } else {
            // Width calculation: elements * (cellSize + spacing) + padding
            return CGFloat(elements.count) * (cellSize + cellSize * 0.1)
        }
    }
    
    private func createDraggableElement(for element: String) -> some View {
        DraggableElementView(
            element: element,
            isDragging: dragState?.element == element,
            onDragStarted: { location in
                let localLocation = geometryFrame.convert(from: location)
                onDragStarted(element, localLocation)
            },
            onDragChanged: { value in
                onDragChanged(value, geometryFrame)
            },
            onDragEnded: onDragEnded
        )
    }
    
    private func createDropHint() -> some View {
        Text("Drop here to remove")
            .font(.system(size: cellSize * 0.2))
            .foregroundColor(.gray)
            .opacity(isOverElementList ? 1.0 : 0.5)
            .animation(.easeInOut, value: isOverElementList)
            .frame(width: cellSize * 2)
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
    @State private var currentCells: [any DataStructureCell] = []
    @State private var connectionStates: [(id: String, state: ConnectionDisplayState)] = []
    @State private var dragState: (element: String, location: CGPoint)?
    @State private var hoveredCellIndex: Int?
    @State private var renderCycle = UUID()
    @State private var draggingFromCellIndex: Int?
    @State private var isOverElementList: Bool = false
    @State private var droppedElements: [String] = []
    @StateObject private var cellSizeManager = CellSizeManager()
    
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
        self._currentCells = State(initialValue: cells)
    }
    
    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            handleFrameChange(newFrame)
        }
        .onChange(of: cells.map(\.id)) { _ in
            updateLayout()
        }
        .onChange(of: connections.map(\.id)) { _ in
            updateLayout()
        }
        .onChange(of: layoutType) { newType in
            handleLayoutTypeChange(newType)
        }
        .environmentObject(cellSizeManager)
    }
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        let cellSize = adaptiveCellSize(for: geometry.size)
        let bottomPadding = adaptiveElementListPadding(for: geometry.size)
        
        return ZStack {
            dataStructureArea(geometry: geometry, cellSize: cellSize)
            
            if let dragState = dragState {
                draggedElementOverlay(dragState: dragState, geometry: geometry)
            }
            
            elementsListArea(geometry: geometry, cellSize: cellSize, bottomPadding: bottomPadding)
        }
        .onChange(of: cellSize) { newSize in
            cellSizeManager.updateSize(for: geometry.size)
        }
        .preference(key: FramePreferenceKey.self, value: CGRect(origin: .zero, size: geometry.size))
    }
    
    private func dataStructureArea(geometry: GeometryProxy, cellSize: CGFloat) -> some View {
        ZStack {
            ConnectionsLayer(connectionStates: connectionStates)
            
            CellsLayer(
                layoutCells: layoutCells,
                hoveredCellIndex: hoveredCellIndex,
                cellSize: cellSize,
                renderCycle: renderCycle,
                dragState: dragState,
                draggingFromCellIndex: draggingFromCellIndex,
                geometry: geometry,
                onDragChanged: { value, frame in
                    if dragState == nil {
                        // Find the cell being dragged by checking position
                        let localLocation = frame.convert(from: value.location)
                        let index = layoutCells.firstIndex { cell in
                            let distance = sqrt(
                                pow(cell.position.x - localLocation.x, 2) +
                                pow(cell.position.y - localLocation.y, 2)
                            )
                            return distance < cellSize / 2
                        }
                        
                        if let index = index, !layoutCells[index].value.isEmpty {
                            draggingFromCellIndex = index
                            dragState = (element: layoutCells[index].value, location: localLocation)
                        }
                    }
                    handleDragChanged(value, in: frame)
                },
                onDragEnded: handleDragEnded
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func draggedElementOverlay(dragState: (element: String, location: CGPoint), geometry: GeometryProxy) -> some View {
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
    
    private func elementsListArea(geometry: GeometryProxy, cellSize: CGFloat, bottomPadding: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ElementsListView(
                    availableElements: availableElements,
                    droppedElements: droppedElements,
                    dragState: dragState,
                    isOverElementList: isOverElementList,
                    onDragStarted: { element, location in
                        dragState = (element, location)
                    },
                    onDragChanged: handleDragChanged,
                    onDragEnded: handleDragEnded,
                    geometryFrame: geometry.frame(in: .global),
                    cellSize: cellSize
                )
                .onHover { isHovered in
                    isOverElementList = isHovered
                }
                Spacer()
            }
        }
        .padding(.bottom, bottomPadding)
    }
    
    private func handleFrameChange(_ newFrame: CGRect) {
        if newFrame != frame {
            frame = newFrame
            print("Frame updated to: \(newFrame)")
            updateLayout()
        }
    }
    
    private func handleLayoutTypeChange(_ newType: DataStructureLayoutType) {
        layoutManager.setLayoutType(newType)
        updateLayout()
    }
    
    private func adaptiveCellSize(for size: CGSize) -> CGFloat {
        // Base size on the smaller dimension, with a reasonable range
        let dimension = min(size.width, size.height)
        let baseSize = dimension * 0.15 // Increased from 0.1 to 0.15 for better visibility
        return min(max(baseSize, 60), 100) // Increased min and max sizes
    }
    
    private func adaptiveElementListPadding(for size: CGSize) -> CGFloat {
        // More padding on larger screens
        return size.height > 800 ? 100 : 8
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, in globalFrame: CGRect) {
        let localLocation = globalFrame.convert(from: value.location)
        if dragState != nil {
            dragState?.location = localLocation
        }
        
        // Update element list detection for bottom area only
        let elementListY = globalFrame.height - (adaptiveElementListPadding(for: globalFrame.size) + 58)
        isOverElementList = localLocation.y >= elementListY
        
        // Debug prints for drag state
        if let dragState = dragState {
            print("Dragging element: \(dragState.element)")
            print("Drag location: \(localLocation)")
            print("Element list Y threshold: \(elementListY)")
            print("Is over element list: \(isOverElementList)")
        }
        
        // Only look for cell targets if not over element list
        if !isOverElementList {
            // Find closest cell
            let closestCell = layoutCells.enumerated()
                .min(by: { first, second in
                    let distance1 = distance(from: first.element.position, to: localLocation)
                    let distance2 = distance(from: second.element.position, to: localLocation)
                    return distance1 < distance2
                })
            
            if let closest = closestCell,
               distance(from: closest.element.position, to: localLocation) < cellSizeManager.size {
                hoveredCellIndex = closest.offset
                print("Hovering over cell \(closest.offset) with value: \(closest.element.value)")
            } else {
                hoveredCellIndex = nil
            }
        } else {
            hoveredCellIndex = nil
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        print("\n=== Drag Ended ===")
        print("Drag state: \(String(describing: dragState))")
        print("Dragging from cell index: \(String(describing: draggingFromCellIndex))")
        print("Hovered cell index: \(String(describing: hoveredCellIndex))")
        print("Is over element list: \(isOverElementList)")
        print("Available elements: \(availableElements)")
        print("Dropped elements: \(droppedElements)")
        print("Layout cells: \(layoutCells.map { "\($0.value)" })")
        
        defer {
            dragState = nil
            hoveredCellIndex = nil
            draggingFromCellIndex = nil
            isOverElementList = false
        }
        
        if isOverElementList {
            // If dragging from a cell, clear that cell and add to dropped elements
            if let fromIndex = draggingFromCellIndex,
               let element = dragState?.element,
               !element.isEmpty {
                print("Dropping element \(element) to element list from cell \(fromIndex)")
                onElementDropped("", fromIndex)
                // Update current cells
                var updatedCells = currentCells
                var cell = updatedCells[fromIndex]
                cell.setValue("")
                updatedCells[fromIndex] = cell
                currentCells = updatedCells
                
                // Only add to droppedElements if it wasn't in availableElements originally
                if !availableElements.contains(element) {
                    print("Adding \(element) to dropped elements")
                    droppedElements.append(element)
                }
                
                // Force layout update with current cells
                updateLayoutWithCurrentCells()
            }
        } else if let cellIndex = hoveredCellIndex,
                  let element = dragState?.element {
            print("Attempting to drop element \(element) into cell \(cellIndex)")
            // Only drop if the target cell is empty or if we're dragging from a different cell
            if layoutCells[cellIndex].value.isEmpty || cellIndex != draggingFromCellIndex {
                // If dragging from a cell, clear that cell first
                if let fromIndex = draggingFromCellIndex {
                    print("Clearing source cell \(fromIndex)")
                    onElementDropped("", fromIndex)
                    // Update current cells for source
                    var updatedCells = currentCells
                    var sourceCell = updatedCells[fromIndex]
                    sourceCell.setValue("")
                    updatedCells[fromIndex] = sourceCell
                    currentCells = updatedCells
                }
                
                print("Dropping \(element) into cell \(cellIndex)")
                onElementDropped(element, cellIndex)
                // Update current cells for target
                var updatedCells = currentCells
                var targetCell = updatedCells[cellIndex]
                targetCell.setValue(element)
                updatedCells[cellIndex] = targetCell
                currentCells = updatedCells
                
                // Remove the element from droppedElements if it was there
                if let index = droppedElements.firstIndex(of: element) {
                    print("Removing \(element) from dropped elements")
                    droppedElements.remove(at: index)
                }
                
                // Force layout update with current cells
                updateLayoutWithCurrentCells()
            }
        }
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    private func updateLayout() {
        guard !frame.isEmpty else { return }
        
        // Calculate scale factor based on current cell size
        let scaleFactor = cellSizeManager.size / 40 // 40 is the base size
        
        // Adjust frame for arrow positioning in linked list
        var adjustedFrame = frame
        if layoutType == .linkedList {
            // Move connection points to cell edges instead of center
            adjustedFrame = CGRect(
                x: frame.origin.x + cellSizeManager.size / 2,
                y: frame.origin.y,
                width: frame.width - cellSizeManager.size,
                height: frame.height
            )
        }
        
        let (newCells, newStates) = layoutManager.updateLayout(
            cells: currentCells,
            connections: connections,
            in: adjustedFrame,
            scale: scaleFactor
        )
        
        layoutCells = newCells
        connectionStates = newStates.enumerated().map { (index, state) in
            (id: "\(index)", state: state)
        }
        renderCycle = UUID()
    }
    
    private func updateLayoutWithCurrentCells() {
        var adjustedFrame = frame
        if layoutType == .linkedList {
            adjustedFrame = CGRect(
                x: frame.origin.x + cellSizeManager.size / 2,
                y: frame.origin.y,
                width: frame.width - cellSizeManager.size,
                height: frame.height
            )
        }
        
        let (newCells, newStates) = layoutManager.updateLayout(
            cells: currentCells,
            connections: connections,
            in: adjustedFrame,
            scale: cellSizeManager.size / 40
        )
        layoutCells = newCells
        connectionStates = newStates.enumerated().map { (index, state) in
            (id: "\(index)", state: state)
        }
        renderCycle = UUID()
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

// Update CellView to use the environment object
struct CellView: View {
    let state: CellDisplayState
    @EnvironmentObject private var cellSizeManager: CellSizeManager
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(state.style.fillColor)
                .overlay(
                    Rectangle()
                        .stroke(
                            state.style.strokeColor,
                            style: StrokeStyle(
                                lineWidth: state.style.strokeWidth,
                                dash: state.style.isDashed ? [5] : []
                            )
                        )
                )
                .shadow(
                    color: state.style.strokeColor.opacity(0.5),
                    radius: state.style.glowRadius
                )
                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                .cornerRadius(cellSizeManager.size * 0.1)
            
            // Cell value or placeholder
            if !state.value.isEmpty {
                Text(state.value)
                    .font(.system(size: cellSizeManager.size * 0.4))
                    .foregroundColor(.black)
            } else {
                Text("?")
                    .font(.system(size: cellSizeManager.size * 0.4))
                    .foregroundColor(.gray)
            }
            
            // Optional label
            if let label = state.label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .offset(y: -cellSizeManager.size * 0.8)
            }
        }
    }
} 