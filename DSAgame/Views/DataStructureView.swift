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
        // Main element with outline
        Rectangle()
            .fill(Color(red: 0.96, green: 0.95, blue: 0.91))  // Same beige as cells
            .overlay(
                Rectangle()
                    .stroke(
                        Color(red: 0.2, green: 0.2, blue: 0.2),  // Same dark outline as cells
                        lineWidth: 3.6  // Same as cell stroke width
                    )
            )
            .overlay(
                Text(element)
                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                    .foregroundColor(.black)
            )
            .frame(width: cellSizeManager.size, height: cellSizeManager.size)
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
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
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

// Add zoom and pan state manager
class ZoomPanState: ObservableObject {
    @Published var steadyZoom: CGFloat = 1.0
    @Published var steadyPan: CGSize = .zero
}

// Add grid background view
struct GridBackground: View {
    let cellSize: CGFloat = 20 // Size of each grid cell
    let lineWidth: CGFloat = 0.3
    let lineColor: Color = .blue.opacity(0.3)
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Vertical lines
                let horizontalLineCount = Int(geometry.size.width / cellSize) + 1
                for i in 0...horizontalLineCount {
                    let x = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                let verticalLineCount = Int(geometry.size.height / cellSize) + 1
                for i in 0...verticalLineCount {
                    let y = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(lineColor, lineWidth: lineWidth)
        }
        .background(Color.white)
    }
}

// Add MultipleChoiceView before DataStructureView
struct MultipleChoiceView: View {
    let answers: [String]
    let selectedAnswer: String
    let onAnswerSelected: (String) -> Void
    @EnvironmentObject private var cellSizeManager: CellSizeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Select the correct answer:")
                .font(.system(.headline, design: .monospaced))
                .padding(.bottom, 5)
            
            HStack(spacing: cellSizeManager.size * 0.5) {
                ForEach(answers, id: \.self) { answer in
                    Button(action: {
                        onAnswerSelected(answer)
                    }) {
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main rectangle with outline
                            Rectangle()
                                .fill(selectedAnswer == answer ? Color.blue : Color(red: 0.96, green: 0.95, blue: 0.91))
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                )
                                .animation(.spring(response: 0.1, dampingFraction: 0.5, blendDuration: 0), value: selectedAnswer)
                            
                            Text(answer)
                                .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                .foregroundColor(selectedAnswer == answer ? .white : .black)
                        }
                    }
                    .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 30)
    }
}

struct DataStructureView: View {
    let layoutType: DataStructureLayoutType
    let cells: [any DataStructureCell]
    let connections: [any DataStructureConnection]
    let availableElements: [String]?
    let onElementDropped: (String, Int) -> Void
    let isAutoPlaying: Bool
    let onPlayPausePressed: () -> Void
    let autoPlayInterval: TimeInterval
    let zoomPanState: VisualizationZoomPanState
    let hint: String?
    let lineComment: String?
    let isMultipleChoice: Bool
    let multipleChoiceAnswers: [String]
    let onMultipleChoiceAnswerSelected: (String) -> Void
    let selectedMultipleChoiceAnswer: String
    @Environment(\.presentationMode) var presentationMode
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
    @State private var showingHint = false
    @StateObject private var cellSizeManager = CellSizeManager()
    
    // Keep gesture states separate as they are temporary
    @GestureState private var gestureZoom: CGFloat = 1.0
    @GestureState private var gesturePan: CGSize = .zero
    
    init(
        layoutType: DataStructureLayoutType,
        cells: [any DataStructureCell],
        connections: [any DataStructureConnection],
        availableElements: [String]? = nil,
        onElementDropped: @escaping (String, Int) -> Void = { _, _ in },
        isAutoPlaying: Bool = false,
        onPlayPausePressed: @escaping () -> Void = {},
        autoPlayInterval: TimeInterval = 4.0,
        zoomPanState: VisualizationZoomPanState,
        hint: String? = nil,
        lineComment: String? = nil,
        isMultipleChoice: Bool = false,
        multipleChoiceAnswers: [String] = [],
        onMultipleChoiceAnswerSelected: @escaping (String) -> Void = { _ in },
        selectedMultipleChoiceAnswer: String = ""
    ) {
        print("\n=== Initializing DataStructureView ===")
        print("Multiple choice enabled: \(isMultipleChoice)")
        if isMultipleChoice {
            print("Multiple choice answers: \(multipleChoiceAnswers)")
            print("Selected answer: \(selectedMultipleChoiceAnswer)")
        }
        
        self.layoutType = layoutType
        self.cells = cells
        self.connections = connections
        self.availableElements = availableElements
        self.onElementDropped = onElementDropped
        self.isAutoPlaying = isAutoPlaying
        self.onPlayPausePressed = onPlayPausePressed
        self.autoPlayInterval = autoPlayInterval
        self.zoomPanState = zoomPanState
        self.hint = hint
        self.lineComment = lineComment
        self.isMultipleChoice = isMultipleChoice
        self.multipleChoiceAnswers = multipleChoiceAnswers
        self.onMultipleChoiceAnswerSelected = onMultipleChoiceAnswerSelected
        self.selectedMultipleChoiceAnswer = selectedMultipleChoiceAnswer
        self._layoutManager = State(initialValue: DataStructureLayoutManager(layoutType: layoutType))
        self._currentCells = State(initialValue: cells)
        
        print("Initialization complete")
    }
    
    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            handleFrameChange(newFrame)
        }
        .onChange(of: cells.map(\.id)) { _ in
            print("\nCells changed in DataStructureView")
            print("Is multiple choice: \(isMultipleChoice)")
            print("Multiple choice answers: \(multipleChoiceAnswers)")
            print("Selected answer: \(selectedMultipleChoiceAnswer)")
            updateLayout()
        }
        .onChange(of: connections.map(\.id)) { _ in
            updateLayout()
        }
        .onChange(of: layoutType) { _ in
            updateLayout()
        }
        .onChange(of: frame) { _ in
            updateLayout()
        }
        .onAppear {
            print("\nDataStructureView body appeared")
            print("Is multiple choice: \(isMultipleChoice)")
            print("Multiple choice answers: \(multipleChoiceAnswers)")
            print("Selected answer: \(selectedMultipleChoiceAnswer)")
            updateLayout()
        }
        .environmentObject(cellSizeManager)
    }
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        let cellSize = adaptiveCellSize(for: geometry.size)
        let topPadding = adaptiveElementListPadding(for: geometry.size)
        
        return ZStack {
            // Single container for data structure area
            ZStack {
                // Background and gesture handler
                GridBackground()
                    .contentShape(Rectangle())
                    .gesture(
                        MagnificationGesture()
                            .updating($gestureZoom) { value, gestureZoom, _ in
                                gestureZoom = value
                            }
                            .onEnded { value in
                                zoomPanState.steadyZoom = min(max(1.0, zoomPanState.steadyZoom * value), 3.0)
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .updating($gesturePan) { value, gesturePan, _ in
                                if dragState == nil {  // Only pan when not dragging elements
                                    gesturePan = value.translation
                                }
                            }
                            .onEnded { value in
                                if dragState == nil {  // Only update pan when not dragging elements
                                    zoomPanState.steadyPan = CGSize(
                                        width: zoomPanState.steadyPan.width + value.translation.width,
                                        height: zoomPanState.steadyPan.height + value.translation.height
                                    )
                                }
                            }
                    )
                
                // Data structure content
                dataStructureArea(geometry: geometry, cellSize: cellSize)
                    .scaleEffect(zoomPanState.steadyZoom * gestureZoom)
                    .offset(CGSize(
                        width: zoomPanState.steadyPan.width + gesturePan.width,
                        height: zoomPanState.steadyPan.height + gesturePan.height
                    ))
            }
            
            // Overlay elements that should not be transformed
            if let dragState = dragState {
                draggedElementOverlay(dragState: dragState, geometry: geometry)
            }
            
            VStack {
                // Top controls
                HStack {
                    // Exit button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        buttonBackground {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(.leading, 30)
                    
                    // Play/Pause button
                    Button(action: onPlayPausePressed) {
                        buttonBackground {
                            Image(systemName: isAutoPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundColor(canAutoPlay() ? .blue : .gray)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(.leading, 10)
                    .disabled(!canAutoPlay())
                    
                    Spacer()
                    
                    // Hint button - only show if hint is available
                    if let hint = hint {
                        Button(action: {
                            showingHint = true
                        }) {
                            buttonBackground {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title)
                                        .foregroundColor(.yellow)
                                    Text("Need a hint?")
                                        .foregroundColor(.primary)
                                        .font(.system(.body, design: .monospaced))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 200, height: 44)
                        .padding(.trailing, 20)
                    }
                    
                    // Reset button
                    Button(action: {
                        withAnimation(.spring()) {
                            zoomPanState.steadyZoom = 1.0
                            zoomPanState.steadyPan = .zero
                        }
                    }) {
                        buttonBackground {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 30)
                }
                .padding(.top, 30)
                
                Spacer()
                
                VStack(spacing: 20) {
                    if isMultipleChoice {
                        MultipleChoiceView(
                            answers: multipleChoiceAnswers,
                            selectedAnswer: selectedMultipleChoiceAnswer,
                            onAnswerSelected: onMultipleChoiceAnswerSelected
                        )
                    } else if let elements = availableElements, !elements.isEmpty {
                        // Elements list above subtitles
                        ElementsListView(
                            availableElements: elements,
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
                        .padding(.horizontal, 30)
                    }
                    
                    // Subtitles at the bottom
                    if let comment = lineComment {
                        Text(comment)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 120)
                            .padding(.top, 30)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Hint overlay
            if showingHint {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingHint = false
                        }
                    
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                            Text("Hint")
                                .font(.system(.title2, design: .monospaced).weight(.bold))
                        }
                        
                        ScrollView {
                            Text(hint ?? "")
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Button(action: {
                            showingHint = false
                        }) {
                            buttonBackground {
                                Text("Got it!")
                                    .foregroundColor(.blue)
                                    .font(.system(.body, design: .monospaced).weight(.bold))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 120, height: 40)
                        .padding(.top, 20)
                    }
                    .padding(40)
                    .background(
                        ZStack {
                            // Shadow layer
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            // Main box
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                        }
                    )
                    .frame(minWidth: 400, maxWidth: 600)
                    .fixedSize(horizontal: true, vertical: true)  // Size to fit content
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)  // Center in screen
                }
            }
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
        // More padding on larger screens, increased by 20
        return size.height > 800 ? 120 : 30  // Increased from 100 to 120 and from 8 to 28
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, in globalFrame: CGRect) {
        let localLocation = globalFrame.convert(from: value.location)
        let currentScale = zoomPanState.steadyZoom * gestureZoom
        
        // Calculate the center of the frame
        let centerX = globalFrame.width / 2
        let centerY = globalFrame.height / 2
        
        // Calculate total pan offset
        let totalPanX = zoomPanState.steadyPan.width + gesturePan.width
        let totalPanY = zoomPanState.steadyPan.height + gesturePan.height
        
        // Adjust for zoom and pan, taking into account that zoom happens from center
        let adjustedLocation = CGPoint(
            x: ((localLocation.x - totalPanX - centerX) / currentScale) + centerX,
            y: ((localLocation.y - totalPanY - centerY) / currentScale) + centerY
        )
        
        if dragState != nil {
            dragState?.location = localLocation
        } else {
            // When starting a drag, use adjusted coordinates for hit testing
            let index = layoutCells.firstIndex { cell in
                let distance = sqrt(
                    pow(cell.position.x - adjustedLocation.x, 2) +
                    pow(cell.position.y - adjustedLocation.y, 2)
                )
                return distance < cellSizeManager.size / 2
            }
            
            if let index = index, !layoutCells[index].value.isEmpty {
                draggingFromCellIndex = index
                // Start the drag at the actual cursor position
                dragState = (element: layoutCells[index].value, location: localLocation)
            }
        }
        
        // Calculate the element list frame at the bottom
        let listHeight = cellSizeManager.size * 1.5
        let listY = globalFrame.height - 180 // Adjusted to account for padding and subtitle
        let listWidth = calculateListWidth()
        let listX = (globalFrame.width - listWidth) / 2
        
        // Add generous padding to make the hit area larger
        let dropPadding: CGFloat = cellSizeManager.size * 1.2 // Increased padding
        let dropZone = CGRect(
            x: listX - dropPadding,
            y: listY - dropPadding,
            width: listWidth + (dropPadding * 2),
            height: listHeight + (dropPadding * 2)
        )
        
        // Check if any part of the dragged element intersects with the drop zone
        let draggedElementSize = cellSizeManager.size
        let draggedElementFrame = CGRect(
            x: localLocation.x - draggedElementSize/2,
            y: localLocation.y - draggedElementSize/2,
            width: draggedElementSize,
            height: draggedElementSize
        )
        
        isOverElementList = dropZone.intersects(draggedElementFrame)
        
        // Only look for cell targets if not over element list
        if !isOverElementList {
            // Find closest cell using adjusted coordinates
            let closestCell = layoutCells.enumerated()
                .min(by: { first, second in
                    let distance1 = distance(from: first.element.position, to: adjustedLocation)
                    let distance2 = distance(from: second.element.position, to: adjustedLocation)
                    return distance1 < distance2
                })
            
            if let closest = closestCell,
               distance(from: closest.element.position, to: adjustedLocation) < cellSizeManager.size {
                hoveredCellIndex = closest.offset
            } else {
                hoveredCellIndex = nil
            }
        } else {
            hoveredCellIndex = nil
        }
    }
    
    private func calculateListWidth() -> CGFloat {
        let elements = (availableElements ?? []) + droppedElements
        if elements.isEmpty {
            return cellSizeManager.size * 3 // Width for "Drop here to remove" text
        } else {
            return min(
                CGFloat(elements.count) * cellSizeManager.size +
                CGFloat(elements.count - 1) * (cellSizeManager.size * 0.2) + // spacing between elements
                (cellSizeManager.size * 0.4), // padding (0.2 on each side)
                UIScreen.main.bounds.width * 0.8 // Maximum width of 80% of screen width
            )
        }
    }
    
    private var topPadding: CGFloat {
        adaptiveElementListPadding(for: frame.size)
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        
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
                if !(availableElements?.contains(element) ?? false) {
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
    
    private func buttonBackground<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ZStack {
            // Shadow layer
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
            
            // Main Rectangle
            Rectangle()
                .fill(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                )
            
            content()
        }
    }
    
    private func canAutoPlay() -> Bool {
        // Can auto-play if there are cells to display and we're not dragging
        return !cells.isEmpty && !currentCells.isEmpty && dragState == nil && (availableElements ?? []).isEmpty
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
        
        let zoomPanState = VisualizationZoomPanState()
        
        DataStructureView(
            layoutType: .linkedList,
            cells: cells,
            connections: connections,
            availableElements: ["4", "5", "6"],
            onElementDropped: { _, _ in },
            isAutoPlaying: false,
            onPlayPausePressed: {},
            autoPlayInterval: 4.0,
            zoomPanState: zoomPanState,
            hint: "This is a hint",
            lineComment: "This is a line comment",
            isMultipleChoice: false,
            multipleChoiceAnswers: [],
            onMultipleChoiceAnswerSelected: { _ in },
            selectedMultipleChoiceAnswer: ""
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
            // Shadow layer
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
            
            // Main cell with outline
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
                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
            
            // Cell value or placeholder
            if !state.value.isEmpty {
                Text(state.value)
                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                    .foregroundColor(.black)
            } else {
                Text("?")
                    .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // Optional label
            if let label = state.label {
                Text(label)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .offset(y: -cellSizeManager.size * 0.8)
            }
        }
    }
}