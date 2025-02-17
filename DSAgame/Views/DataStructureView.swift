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
                        print("DraggableElementView - Drag changed for element: \(element)")
                        print("  isDragging: \(isDragging)")
                        if !isDragging {
                            print("  Starting drag at: \(value.location)")
                            onDragStarted(value.location)
                        }
                        onDragChanged(value)
                    }
                    .onEnded { value in
                        print("DraggableElementView - Drag ended for element: \(element)")
                        onDragEnded(value)
                    }
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
            .contentShape(Rectangle())  // Make entire area draggable
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        onDragChanged(value, geometryFrame)
                    }
                    .onEnded { value in
                        onDragEnded(value)
                    }
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

// Add this extension before the DataStructureView struct
extension View {
    func buttonBackground<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
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
}

// Add this before DataStructureView
class DroppedElementsState: ObservableObject {
    @Published var elements: [String] = []
}

private struct DroppedElementsKey: EnvironmentKey {
    static let defaultValue = DroppedElementsState()
}

extension EnvironmentValues {
    var droppedElementsState: DroppedElementsState {
        get { self[DroppedElementsKey.self] }
        set { self[DroppedElementsKey.self] = newValue }
    }
}

// Add this before DataStructureView
struct DataStructureViewContainer: View {
    @StateObject private var droppedElementsState = DroppedElementsState()
    let layoutType: DataStructureLayoutType
    let cells: [any DataStructureCell]
    let connections: [any DataStructureConnection]
    let availableElements: [String]?
    let onElementDropped: (String, Int) -> Void
    let isAutoPlaying: Bool
    let onPlayPausePressed: () -> Void
    let autoPlayInterval: TimeInterval
    let hint: String?
    let lineComment: String?
    let isMultipleChoice: Bool
    let multipleChoiceAnswers: [String]
    let onMultipleChoiceAnswerSelected: (String) -> Void
    let selectedMultipleChoiceAnswer: String
    let onShowAnswer: () -> Void
    let isCompleted: Bool
    let questionId: String
    
    var body: some View {
        DataStructureView(
            layoutType: layoutType,
            cells: cells,
            connections: connections,
            availableElements: availableElements,
            onElementDropped: onElementDropped,
            isAutoPlaying: isAutoPlaying,
            onPlayPausePressed: onPlayPausePressed,
            autoPlayInterval: autoPlayInterval,
            hint: hint,
            lineComment: lineComment,
            isMultipleChoice: isMultipleChoice,
            multipleChoiceAnswers: multipleChoiceAnswers,
            onMultipleChoiceAnswerSelected: onMultipleChoiceAnswerSelected,
            selectedMultipleChoiceAnswer: selectedMultipleChoiceAnswer,
            onShowAnswer: onShowAnswer,
            isCompleted: isCompleted,
            questionId: questionId
        )
        .environment(\.droppedElementsState, droppedElementsState)
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
    let hint: String?
    let lineComment: String?
    let isMultipleChoice: Bool
    let multipleChoiceAnswers: [String]
    let onMultipleChoiceAnswerSelected: (String) -> Void
    let selectedMultipleChoiceAnswer: String
    let onShowAnswer: () -> Void
    let isCompleted: Bool
    let questionId: String
    @Environment(\.presentationMode) var presentationMode
    @State private var frame: CGRect = .zero
    @State private var layoutManager: DataStructureLayoutManager
    @State private var layoutCells: [any DataStructureCell] = []
    @State private var currentCells: [any DataStructureCell] = []
    @State private var originalCells: [any DataStructureCell] = []
    @State private var hasChanges: Bool = false
    @State private var connectionStates: [(id: String, state: ConnectionDisplayState)] = []
    @State private var dragState: (element: String, location: CGPoint)?
    @State private var hoveredCellIndex: Int?
    @State private var renderCycle = UUID()
    @State private var draggingFromCellIndex: Int?
    @State private var isOverElementList: Bool = false
    @Environment(\.droppedElementsState) private var droppedElementsState
    @State private var originalAvailableElements: [String] = []  // Track original available elements
    @State private var showingHint = false
    @State private var showingGuide = false
    @State private var currentGuideStep = 0
    @StateObject private var cellSizeManager = CellSizeManager()
    
    private var droppedElements: [String] {
        get { droppedElementsState.elements }
        set { droppedElementsState.elements = newValue }
    }
    
    init(
        layoutType: DataStructureLayoutType,
        cells: [any DataStructureCell],
        connections: [any DataStructureConnection],
        availableElements: [String]? = nil,
        onElementDropped: @escaping (String, Int) -> Void = { _, _ in },
        isAutoPlaying: Bool = false,
        onPlayPausePressed: @escaping () -> Void = {},
        autoPlayInterval: TimeInterval = 4.0,
        hint: String? = nil,
        lineComment: String? = nil,
        isMultipleChoice: Bool = false,
        multipleChoiceAnswers: [String] = [],
        onMultipleChoiceAnswerSelected: @escaping (String) -> Void = { _ in },
        selectedMultipleChoiceAnswer: String = "",
        onShowAnswer: @escaping () -> Void = {},
        isCompleted: Bool = false,
        questionId: String
    ) {
        print("\n=== DataStructureView Init ===")
        print("availableElements: \(String(describing: availableElements))")
        print("Initial droppedElements: []")
        
        self.layoutType = layoutType
        self.cells = cells
        self.connections = connections
        self.availableElements = availableElements
        self.onElementDropped = onElementDropped
        self.isAutoPlaying = isAutoPlaying
        self.onPlayPausePressed = onPlayPausePressed
        self.autoPlayInterval = autoPlayInterval
        self.hint = hint
        self.lineComment = lineComment
        self.isMultipleChoice = isMultipleChoice
        self.multipleChoiceAnswers = multipleChoiceAnswers
        self.onMultipleChoiceAnswerSelected = onMultipleChoiceAnswerSelected
        self.selectedMultipleChoiceAnswer = selectedMultipleChoiceAnswer
        self.onShowAnswer = onShowAnswer
        self.isCompleted = isCompleted
        self._layoutManager = State(initialValue: DataStructureLayoutManager(layoutType: layoutType))
        self._currentCells = State(initialValue: cells)
        self._originalCells = State(initialValue: cells)
        self._originalAvailableElements = State(initialValue: availableElements ?? [])
        self.questionId = questionId
        
        // Check if this is the first time viewing any level
        let hasSeenGuide = UserDefaults.standard.bool(forKey: "hasSeenDataStructureGuide")
        print("\n=== Guide Initialization ===")
        print("Has seen guide: \(hasSeenGuide)")
        self._showingGuide = State(initialValue: !hasSeenGuide)
        print("Setting initial showingGuide to: \(!hasSeenGuide)")
        self._currentGuideStep = State(initialValue: 0)
        
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
            print("ShowingGuide state: \(showingGuide)")
            updateLayout()
        }
        .onChange(of: showingGuide) { newValue in
            // When the guide is closed, mark it as seen
            print("\n=== Guide State Changed ===")
            print("ShowingGuide changed to: \(newValue)")
            if !newValue {
                print("Guide closed, marking as seen in UserDefaults")
                UserDefaults.standard.set(true, forKey: "hasSeenDataStructureGuide")
            }
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
                
                // Data structure content
                dataStructureArea(geometry: geometry, cellSize: cellSize)
            }
            
            // Overlay elements that should not be transformed
            if let dragState = dragState {
                draggedElementOverlay(dragState: dragState, geometry: geometry)
            }
            
            VStack {
                // Top controls
                HStack {
                    // Guide button
                    Button(action: {
                        showingGuide = true
                        currentGuideStep = 0
                    }) {
                        buttonBackground {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(.leading, 30)
                    
                    // Reset button
                    Button(action: resetToOriginalState) {
                        buttonBackground {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray.opacity(hasChanges ? 0 : 1))
                                .overlay(
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange.opacity(hasChanges ? 1 : 0))
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .padding(.leading, 10)
                    .allowsHitTesting(hasChanges)
                    
                    // Show Answer button - only show if the question is completed
                    if isCompleted {
                        Button(action: onShowAnswer) {
                            buttonBackground {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .padding(.leading, 10)
                    }
                    
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
                    
                    // Play/Pause button (moved to end)
                    Button(action: onPlayPausePressed) {
                        buttonBackground {
                            Image(systemName: isAutoPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundColor(canAutoPlay() ? .blue : .gray)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 30)
                    .disabled(!canAutoPlay())
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
                    } else if availableElements != nil {
                        // Only show elements list if availableElements was explicitly included in the JSON
                        ElementsListView(
                            availableElements: availableElements ?? [],
                            droppedElementsState: droppedElementsState,
                            dragState: dragState,
                            isOverElementList: isOverElementList,
                            onDragStarted: { element, location in
                                dragState = (element: element, location: location)
                            },
                            onDragChanged: { value, frame in
                                handleDragChanged(value, in: frame)
                            },
                            onDragEnded: handleDragEnded,
                            geometryFrame: geometry.frame(in: .global),
                            cellSize: cellSizeManager.size
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

            // Add guide overlay after the hint overlay
            if showingGuide {
                GuideCard(
                    currentStep: currentGuideStep,
                    onNext: {
                        currentGuideStep += 1
                    },
                    onBack: {
                        currentGuideStep -= 1
                    },
                    onClose: {
                        showingGuide = false
                        currentGuideStep = 0
                    },
                    geometry: geometry
                )
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
        
        if dragState != nil {
            dragState?.location = localLocation
        } else {
            // When starting a drag, use coordinates for hit testing
            let index = layoutCells.firstIndex { cell in
                let distance = sqrt(
                    pow(cell.position.x - localLocation.x, 2) +
                    pow(cell.position.y - localLocation.y, 2)
                )
                return distance < cellSizeManager.size / 2
            }
            
            if let index = index, !layoutCells[index].value.isEmpty {
                print("  Starting drag from cell \(index) with value \(layoutCells[index].value)")
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
        
        let wasOverList = isOverElementList
        isOverElementList = dropZone.intersects(draggedElementFrame)
        if isOverElementList != wasOverList {
            print("  isOverElementList changed to: \(isOverElementList)")
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
        if isOverElementList, let element = dragState?.element {
            // If dragging from a cell, clear that cell
            if let fromIndex = draggingFromCellIndex {
                print("\nDropping element \(element) to element list")
                print("Current droppedElements before: \(droppedElements)")
                
                // First add to dropped elements
                droppedElementsState.elements.append(element)
                print("droppedElements after append: \(droppedElementsState.elements)")
                print("Added \(element) to dropped elements (total count: \(droppedElementsState.elements.count))")
                
                // Then update the cell
                onElementDropped("", fromIndex)
                var updatedCells = currentCells
                var cell = updatedCells[fromIndex]
                cell.setValue("")
                updatedCells[fromIndex] = cell
                currentCells = updatedCells
                hasChanges = true
                
                // Force layout updates last
                renderCycle = UUID()
                updateLayoutWithCurrentCells()
                
                print("Final droppedElements state: \(droppedElementsState.elements)")
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
                hasChanges = true  // Mark that changes were made
                
                // Remove one instance of the element from droppedElements if it was there
                if let index = droppedElementsState.elements.firstIndex(of: element) {
                    print("Removing \(element) from dropped elements")
                    droppedElementsState.elements.remove(at: index)
                }
                
                // Force layout update with current cells
                updateLayoutWithCurrentCells()
            }
        }
        
        // Always mark as changed if we have different elements in cells or dropped list
        let currentCellValues = currentCells.map { $0.value }.filter { !$0.isEmpty }
        let originalCellValues = originalCells.map { $0.value }.filter { !$0.isEmpty }
        let currentElementsState = (currentCellValues + droppedElements).sorted()
        let originalElementsState = (originalCellValues + originalAvailableElements).sorted()
        hasChanges = currentElementsState != originalElementsState
        
        // Clean up state after handling the drop
        dragState = nil
        hoveredCellIndex = nil
        draggingFromCellIndex = nil
        isOverElementList = false
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    private func updateLayout() {
        guard !frame.isEmpty else { return }
        
        print("\n=== updateLayout called ===")
        print("droppedElements state in updateLayout: \(droppedElements)")
        
        // Calculate scale factor based on current cell size
        let scaleFactor = cellSizeManager.size / 40 // 40 is the base size
        
        
        // Don't adjust frame for arrays, only for linked lists
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
        
        print("  - Adjusted frame: \(adjustedFrame)")
        
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
        
        print("droppedElements after layout update: \(droppedElements)")
    }
    
    private func updateLayoutWithCurrentCells() {
        print("\n=== updateLayoutWithCurrentCells called ===")
        print("droppedElements before layout update: \(droppedElements)")
        var adjustedFrame = frame
        // For arrays, we don't need to adjust the frame
        if layoutType == .linkedList {
            adjustedFrame = CGRect(
                x: frame.origin.x + cellSizeManager.size / 2,
                y: frame.origin.y,
                width: frame.width - cellSizeManager.size,
                height: frame.height
            )
        }
        
        let scaleFactor = cellSizeManager.size / 40
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
        print("droppedElements after layout update: \(droppedElements)")
    }
    
    private func canAutoPlay() -> Bool {
        // Can auto-play if there are cells to display and we're not dragging
        return !cells.isEmpty && !currentCells.isEmpty && dragState == nil && (availableElements ?? []).isEmpty
    }

    // Guide card content
    private struct GuideCard: View {
        let currentStep: Int
        let onNext: () -> Void
        let onBack: () -> Void
        let onClose: () -> Void
        let geometry: GeometryProxy
        @EnvironmentObject private var cellSizeManager: CellSizeManager
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onClose()
                    }
                
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("Guide")
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    ScrollView {
                        if currentStep == 0 {
                            // First card - Button functions
                            VStack(alignment: .leading, spacing: 25) {
                                Text("Button Functions")
                                    .font(.system(.title3, design: .monospaced).weight(.bold))
                                    .padding(.bottom, 5)
                                
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    Text("Autoplay")
                                        .font(.system(.body, design: .monospaced))
                                }
                                .padding(.bottom, 5)
                                
                                Text("Autoplay will automatically move through steps (the pause is based on the length of the text) until it reaches a question")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                    .padding(.bottom, 20)
                                
                                HStack {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    Text("Reset")
                                        .font(.system(.body, design: .monospaced))
                                }
                                .padding(.bottom, 5)
                                
                                Text("Reset the current step to its original state if you've moved elements around")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                    .padding(.bottom, 20)
                                
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.green)
                                    Text("Show Answer")
                                        .font(.system(.body, design: .monospaced))
                                }
                                .padding(.bottom, 5)
                                
                                Text("If you have answered a question before, this button will show, and you can either move on or click it to show the correct answer")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                                    .padding(.bottom, 5)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 20)
                        } else if currentStep == 1 {
                            // Second card - Drag and Drop
                            VStack(alignment: .leading, spacing: 25) {
                                Text("Drag and Drop")
                                    .font(.system(.title3, design: .monospaced).weight(.bold))
                                    .padding(.bottom, 10)
                                
                                Text("You can drag elements between cells or to/from the element list to create the correct data structure:")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.bottom, 20)
                                
                                // Example visualization
                                VStack(spacing: 50) {
                                    // First example: Cells with element list
                                    VStack(alignment: .leading, spacing: 25) {
                                        
                                  HStack(spacing: cellSizeManager.size * 0.5) {
                                            // Example cells
                                            ForEach(0..<2) { i in
                                                ZStack {
                                                    // Shadow layer
                                                    Rectangle()
                                                        .fill(Color.black)
                                                        .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                        .offset(x: 6, y: 6)  // Updated shadow offset to 8 points
                                                    
                                                    // Main cell
                                                    Rectangle()
                                                        .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                        .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                        .overlay(
                                                            Rectangle()
                                                                .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                        )
                                                    Text(i == 0 ? "1" : "?")
                                                        .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                                }
                                            }
                                        }
                                        .padding(.bottom, 20)
                                        
                                        VStack(alignment: .leading, spacing: 20) {
                                            // Example element list with elements
                                            ZStack {
                                                // Shadow layer
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .offset(x: 6, y: 6)
                                                
                                                // Main rectangle
                                                Rectangle()
                                                    .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                    )
                                                
                                                // Elements
                                                HStack(spacing: cellSizeManager.size * 0.2) {
                                                    ForEach(["2", "3"], id: \.self) { element in
                                                        ZStack {
                                                            Rectangle()
                                                                .fill(Color(red: 0.96, green: 0.95, blue: 0.91))
                                                                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                                .overlay(
                                                                    Rectangle()
                                                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 3.6)
                                                                )
                                                            Text(element)
                                                                .font(.system(size: cellSizeManager.size * 0.4, design: .monospaced))
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, cellSizeManager.size * 0.2)
                                            }
                                            .frame(width: cellSizeManager.size * 4, height: cellSizeManager.size * 1.2)
                                            
                                            // Empty element list
                                            ZStack {
                                                // Shadow layer
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .offset(x: 6, y: 6)
                                                
                                                // Main rectangle
                                                Rectangle()
                                                    .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                    )
                                                
                                                Text("Drop here to remove")
                                                    .font(.system(size: cellSizeManager.size * 0.35))
                                                    .foregroundColor(.gray)
                                                    .monospaced()
                                            }
                                            .frame(width: cellSizeManager.size * 4, height: cellSizeManager.size * 1.2) 
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 30)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(action: onBack) {
                                buttonBackground {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .foregroundColor(.blue)
                                    .font(.system(.body, design: .monospaced).weight(.bold))
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 120, height: 40)
                        }
                        
                        if currentStep < 1 {
                            Button(action: onNext) {
                                buttonBackground {
                                    HStack {
                                        Text("Next")
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.blue)
                                    .font(.system(.body, design: .monospaced).weight(.bold))
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 120, height: 40)
                        }
                    }
                    .padding(.top, 30)
                }
                .padding(50)
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
                .frame(minWidth: 400, maxWidth: 500)
                .frame(minHeight: 600)
                .fixedSize(horizontal: true, vertical: true)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    private func resetToOriginalState() {
        // Reset cells to original state
        currentCells = originalCells
        
        // Get all elements currently in cells
        let elementsInCells = currentCells.compactMap { cell -> String? in
            let value = cell.value
            return value.isEmpty ? nil : value
        }
        
        // Create a mutable copy of original available elements
        var availableElementsCopy = originalAvailableElements
        
        // Remove elements that are in cells from the available elements
        for element in elementsInCells {
            if let index = availableElementsCopy.firstIndex(of: element) {
                availableElementsCopy.remove(at: index)
            }
        }
        
        // Set the remaining elements as dropped elements
        droppedElementsState.elements = availableElementsCopy
        
        hasChanges = false
        updateLayoutWithCurrentCells()
        renderCycle = UUID()
    }

    private var shouldDisableNextButton: Bool {
        // If the question is already completed, allow moving forward
        if isCompleted {
            return false
        }
        // Otherwise, disable the button
        return true
    }

    private func moveToNextStep() {
        // If the question is completed, move to next step
        if isCompleted {
            currentGuideStep += 1
            renderCycle = UUID()
        }
    }

    private func calculateAutoPlayInterval(comment: String?) -> TimeInterval {
        guard let comment = comment else { return 3.0 }  // Default interval if no comment
        
        // Base interval of 2 seconds
        let baseInterval: TimeInterval = 2.0
        
        // Add 0.05 seconds per character (about 20 chars per second reading speed)
        let additionalTime = TimeInterval(comment.count) * 0.05
        
        // Clamp the total interval between 2 and 7 seconds
        return min(max(baseInterval + additionalTime, 2.0), 7.0)
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
        
        DataStructureViewContainer(
            layoutType: .linkedList,
            cells: cells,
            connections: connections,
            availableElements: ["4", "5", "6"],
            onElementDropped: { _, _ in },
            isAutoPlaying: false,
            onPlayPausePressed: {},
            autoPlayInterval: 4.0,
            hint: "This is a hint",
            lineComment: "This is a line comment",
            isMultipleChoice: false,
            multipleChoiceAnswers: [],
            onMultipleChoiceAnswerSelected: { _ in },
            selectedMultipleChoiceAnswer: "",
            onShowAnswer: {},
            isCompleted: false,
            questionId: "1"
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
                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                .offset(x: 6, y: 6)
            
            // Main cell layer
            Rectangle()
                .fill(state.style.fillColor)
                .frame(width: cellSizeManager.size, height: cellSizeManager.size)
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
