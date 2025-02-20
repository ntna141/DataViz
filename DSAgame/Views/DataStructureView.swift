import SwiftUI


struct DraggableElementView: View {
    let element: String
    let isDragging: Bool
    let onDragStarted: (CGPoint) -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    @EnvironmentObject private var cellSizeManager: CellSizeManager
    
    var body: some View {
        
        Rectangle()
            .fill(Color(red: 0.96, green: 0.95, blue: 0.91))  
            .overlay(
                Rectangle()
                    .stroke(
                        Color(red: 0.2, green: 0.2, blue: 0.2),  
                        lineWidth: 3.6  
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
                    .onEnded { value in
                        onDragEnded(value)
                    }
            )
            .animation(.spring(response: 0.3), value: isDragging)
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
            .contentShape(Rectangle())  
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


struct ConnectionsLayer: View {
    let connectionStates: [(id: String, state: ConnectionDisplayState)]
    
    var body: some View {
        ForEach(connectionStates, id: \.id) { connection in
            ConnectionView(state: connection.state)
        }
    }
}


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
            
            onDragChanged(value, frame)
        }
        
        onDragChanged(value, frame)
    }
}


struct GridBackground: View {
    let cellSize: CGFloat = 20 
    let lineWidth: CGFloat = 0.3
    let lineColor: Color = .blue.opacity(0.3)
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                
                let horizontalLineCount = Int(geometry.size.width / cellSize) + 1
                for i in 0...horizontalLineCount {
                    let x = CGFloat(i) * cellSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                
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
                            
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            
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


extension View {
    func buttonBackground<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ZStack {
            
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
            
            
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


class ElementListState: ObservableObject {
    @Published var currentList: [String]
    
    init(initialElements: [String]? = nil) {
        self.currentList = initialElements ?? []
    }
    
    func reset(with elements: [String]?) {
    }
    
    func hardReset(with elements: [String]?) {
        currentList = []
        
        currentList = []
        
        
        if let elements = elements {
            currentList = elements
        }
    }
    
    func append(_ element: String) {
        currentList.append(element)
    }
    
    func remove(_ element: String) {
        if let index = currentList.firstIndex(of: element) {
            currentList.remove(at: index)
        }
    }
}

private struct ElementListKey: EnvironmentKey {
    static let defaultValue = ElementListState(initialElements: [])
}

extension EnvironmentValues {
    var elementListState: ElementListState {
        get { self[ElementListKey.self] }
        set { self[ElementListKey.self] = newValue }
    }
}


class OriginalCellsState: ObservableObject {
    @Published private(set) var currentCells: [any DataStructureCell]
    
    init(cells: [any DataStructureCell]) {
        self.currentCells = cells.map { cell in
            var copy = (cell as! BasicCell).deepCopy()
            copy.position = cell.position
            return copy
        }
    }
    
    func getCells() -> [any DataStructureCell] {
        return currentCells.map { cell in
            var copy = (cell as! BasicCell).deepCopy()
            copy.position = cell.position
            return copy
        }
    }
    
    func hardReset(with cells: [any DataStructureCell]) {
        
        self.currentCells = cells.map { cell in
            var copy = (cell as! BasicCell).deepCopy()
            copy.position = cell.position
            return copy
        }
    }
}


struct DataStructureViewContainer: View {
    @StateObject private var elementListState: ElementListState
    @StateObject private var originalCellsState: OriginalCellsState
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
        
        
        let state = ElementListState(initialElements: availableElements)
        self._elementListState = StateObject(wrappedValue: state)
        
        
        self._originalCellsState = StateObject(wrappedValue: OriginalCellsState(cells: cells))
        
        
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
        self.questionId = questionId
    }
    
    private func updateOriginalCellsState() {
        originalCellsState.hardReset(with: cells)
    }
    
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
            questionId: questionId,
            elementListState: elementListState,
            originalCellsState: originalCellsState
        )
        .onChange(of: availableElements) { newElements in
            elementListState.hardReset(with: newElements)
        }
        .onAppear {
            updateOriginalCellsState()
        }
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
    @ObservedObject var elementListState: ElementListState
    @ObservedObject var originalCellsState: OriginalCellsState
    @Environment(\.presentationMode) var presentationMode
    @State private var frame: CGRect = .zero
    @State private var layoutManager: DataStructureLayoutManager
    @State private var layoutCells: [any DataStructureCell] = []
    @State private var currentCells: [any DataStructureCell] = []
    @State private var hasChanges: Bool = false
    @State private var connectionStates: [(id: String, state: ConnectionDisplayState)] = []
    @State private var dragState: (element: String, location: CGPoint)?
    @State private var hoveredCellIndex: Int?
    @State private var renderCycle = UUID()
    @State private var draggingFromCellIndex: Int?
    @State private var isOverElementList: Bool = false
    @State private var originalAvailableElements: [String] = []
    @State private var showingHint = false
    @State private var showingGuide = false
    @State private var currentGuideStep = 0
    @StateObject private var cellSizeManager = CellSizeManager()
    
    private var currentList: [String] {
        elementListState.currentList
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
        questionId: String,
        elementListState: ElementListState,
        originalCellsState: OriginalCellsState
    ) {
        
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
        self._originalAvailableElements = State(initialValue: availableElements ?? [])
        self.questionId = questionId
        self.elementListState = elementListState
        self.originalCellsState = originalCellsState
        
        
        let hasSeenGuide = UserDefaults.standard.bool(forKey: "hasSeenDataStructureGuide")
        self._showingGuide = State(initialValue: !hasSeenGuide)
        self._currentGuideStep = State(initialValue: 0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
            
            
            if showingGuide {
                GuideCard(
                    currentStep: currentGuideStep,
                    onNext: {
                        currentGuideStep += 1
                        resetDroppedElementsForCurrentStep()
                    },
                    onBack: {
                        currentGuideStep = max(0, currentGuideStep - 1)
                        resetDroppedElementsForCurrentStep()
                    },
                    onClose: {
                        showingGuide = false
                        currentGuideStep = 0
                        resetDroppedElementsForCurrentStep()
                    },
                    geometry: geometry,
                    elementListState: elementListState
                )
                .environmentObject(cellSizeManager)
            }
        }
        .onPreferenceChange(FramePreferenceKey.self) { newFrame in
            handleFrameChange(newFrame)
        }
        .onAppear {
            
            currentCells = cells.map { cell in
                var copy = (cell as! BasicCell).deepCopy()
                copy.position = cell.position
                return copy
            }
            
            if originalCellsState.getCells().isEmpty {
                originalCellsState.hardReset(with: cells)
            }
            updateLayout()
        }
        .onChange(of: showingGuide) { newValue in
            
            if !newValue {
                UserDefaults.standard.set(true, forKey: "hasSeenDataStructureGuide")
            }
        }
        .onChange(of: cellSizeManager.size) { newSize in
            cellSizeManager.updateSize(for: UIScreen.main.bounds.size)
            
            updateLayout()
        }
        .preference(key: FramePreferenceKey.self, value: CGRect(origin: .zero, size: UIScreen.main.bounds.size))
    }
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        let cellSize = adaptiveCellSize(for: geometry.size)
        let topPadding = adaptiveElementListPadding(for: geometry.size)
        
        return ZStack {
            
            ZStack {
                
                GridBackground()
                    .contentShape(Rectangle())
                
                
                dataStructureArea(geometry: geometry, cellSize: cellSize)
            }
            
            
            if let dragState = dragState {
                draggedElementOverlay(dragState: dragState, geometry: geometry)
            }
            
            VStack {
                
                HStack {
                    
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
                    
                    
                    Button(action: resetCurrentState) {
                        buttonBackground {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title)
                                .foregroundColor(hasChanges ? .orange : .gray)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .padding(.leading, 10)
                    
                    
                    if isCompleted && (isMultipleChoice || availableElements != nil) {
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
                        ElementsListView(
                            elementListState: elementListState,
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
                            
                            Rectangle()
                                .fill(Color.black)
                                .offset(x: 6, y: 6)
                            
                            
                            Rectangle()
                                .fill(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                )
                        }
                    )
                    .frame(minWidth: 400, maxWidth: 600)
                    .fixedSize(horizontal: true, vertical: true)  
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)  
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
            updateLayout()
        }
    }
    
    private func handleLayoutTypeChange(_ newType: DataStructureLayoutType) {
        layoutManager.setLayoutType(newType)
        updateLayout()
    }
    
    private func adaptiveCellSize(for size: CGSize) -> CGFloat {
        
        let dimension = min(size.width, size.height)
        let baseSize = dimension * 0.15 
        return min(max(baseSize, 60), 100) 
    }
    
    private func adaptiveElementListPadding(for size: CGSize) -> CGFloat {
        
        return size.height > 800 ? 120 : 30  
    }
    
    private func handleDragChanged(_ value: DragGesture.Value, in globalFrame: CGRect) {
        let localLocation = globalFrame.convert(from: value.location)
        
        if dragState != nil {
            dragState?.location = localLocation
        } else {
            
            let index = layoutCells.firstIndex { cell in
                let distance = sqrt(
                    pow(cell.position.x - localLocation.x, 2) +
                    pow(cell.position.y - localLocation.y, 2)
                )
                return distance < cellSizeManager.size / 2
            }
            
            if let index = index, !layoutCells[index].value.isEmpty {
                draggingFromCellIndex = index
                dragState = (element: layoutCells[index].value, location: localLocation)
            }
        }
        
        
        let listHeight = cellSizeManager.size * 1.5
        let listY = globalFrame.height - 180 
        let listWidth = calculateListWidth()
        let listX = (globalFrame.width - listWidth) / 2
        
        
        let dropPadding: CGFloat = cellSizeManager.size * 1.2 
        let dropZone = CGRect(
            x: listX - dropPadding,
            y: listY - dropPadding,
            width: listWidth + (dropPadding * 2),
            height: listHeight + (dropPadding * 2)
        )
        
        
        let draggedElementSize = cellSizeManager.size
        let draggedElementFrame = CGRect(
            x: localLocation.x - draggedElementSize/2,
            y: localLocation.y - draggedElementSize/2,
            width: draggedElementSize,
            height: draggedElementSize
        )
        
        let wasOverList = isOverElementList
        isOverElementList = dropZone.intersects(draggedElementFrame)
        
        
        if !isOverElementList {
            
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
        let elements = currentList
        if elements.isEmpty {
            return cellSizeManager.size * 3 
        } else {
            return min(
                CGFloat(elements.count) * cellSizeManager.size +
                CGFloat(elements.count - 1) * (cellSizeManager.size * 0.2) + 
                (cellSizeManager.size * 0.4), 
                UIScreen.main.bounds.width * 0.8 
            )
        }
    }
    
    private var topPadding: CGFloat {
        adaptiveElementListPadding(for: frame.size)
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        if isOverElementList, let element = dragState?.element {
            
            if let fromIndex = draggingFromCellIndex {
                elementListState.append(element)
                
                onElementDropped("", fromIndex)
                var updatedCells = currentCells
                var cell = updatedCells[fromIndex]
                cell.setValue("")
                updatedCells[fromIndex] = cell
                currentCells = updatedCells
                hasChanges = true
                
                
                var updatedLayoutCells = layoutCells
                var layoutCell = updatedLayoutCells[fromIndex]
                layoutCell.setValue("")
                updatedLayoutCells[fromIndex] = layoutCell
                layoutCells = updatedLayoutCells
                
                
                renderCycle = UUID()
            }
        } else if let cellIndex = hoveredCellIndex,
                  let element = dragState?.element {
            
            if layoutCells[cellIndex].value.isEmpty || cellIndex != draggingFromCellIndex {
                
                if let fromIndex = draggingFromCellIndex {
                    onElementDropped("", fromIndex)
                    
                    var updatedCells = currentCells
                    var sourceCell = updatedCells[fromIndex]
                    sourceCell.setValue("")
                    updatedCells[fromIndex] = sourceCell
                    currentCells = updatedCells
                    
                    
                    var updatedLayoutCells = layoutCells
                    var sourceLayoutCell = updatedLayoutCells[fromIndex]
                    sourceLayoutCell.setValue("")
                    updatedLayoutCells[fromIndex] = sourceLayoutCell
                    layoutCells = updatedLayoutCells
                }
                
                onElementDropped(element, cellIndex)
                
                var updatedCells = currentCells
                var targetCell = updatedCells[cellIndex]
                targetCell.setValue(element)
                updatedCells[cellIndex] = targetCell
                currentCells = updatedCells
                
                
                var updatedLayoutCells = layoutCells
                var targetLayoutCell = updatedLayoutCells[cellIndex]
                targetLayoutCell.setValue(element)
                updatedLayoutCells[cellIndex] = targetLayoutCell
                layoutCells = updatedLayoutCells
                
                hasChanges = true
                
                
                elementListState.remove(element)
                
                
                renderCycle = UUID()
            }
        }
        
        
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
        
        
        let scaleFactor = cellSizeManager.size / 40 
        
        
        var adjustedFrame = frame
        if layoutType == .linkedList {
            
            adjustedFrame = CGRect(
                x: frame.origin.x + cellSizeManager.size / 2,
                y: frame.origin.y,
                width: frame.width - cellSizeManager.size,
                height: frame.height
            )
        }
        
        let cellsToLayout = currentCells.map { cell in
            var copy = (cell as! BasicCell).deepCopy()
            copy.position = cell.position 
            return copy
        }
        
        let (newCells, newStates) = layoutManager.updateLayout(
            cells: cellsToLayout,
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
        
        let scaleFactor = cellSizeManager.size / 40
        
        
        let cellsToLayout = currentCells.map { cell in
            var copy = (cell as! BasicCell).deepCopy()
            copy.position = cell.position 
            return copy
        }
        
        let (newCells, newStates) = layoutManager.updateLayout(
            cells: cellsToLayout,
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
    
    private func canAutoPlay() -> Bool {
        
        return !cells.isEmpty && !currentCells.isEmpty && dragState == nil && (availableElements ?? []).isEmpty
    }

    
    private struct GuideCard: View {
        let currentStep: Int
        let onNext: () -> Void
        let onBack: () -> Void
        let onClose: () -> Void
        let geometry: GeometryProxy
        @ObservedObject var elementListState: ElementListState
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
                            
                            VStack(alignment: .leading, spacing: 25) {
                                Text("Drag and Drop")
                                    .font(.system(.title3, design: .monospaced).weight(.bold))
                                    .padding(.bottom, 10)
                                
                                Text("You can drag elements between cells or to/from the element list to create the correct data structure:")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.bottom, 20)
                                
                                
                                VStack(spacing: 50) {
                                    
                                    VStack(alignment: .leading, spacing: 25) {
                                        
                                  HStack(spacing: cellSizeManager.size * 0.5) {
                                            
                                            ForEach(0..<2) { i in
                                                ZStack {
                                                    
                                                    Rectangle()
                                                        .fill(Color.black)
                                                        .frame(width: cellSizeManager.size, height: cellSizeManager.size)
                                                        .offset(x: 6, y: 6)  
                                                    
                                                    
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
                                            
                                            ZStack {
                                                
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .offset(x: 6, y: 6)
                                                
                                                
                                                Rectangle()
                                                    .fill(Color(red: 0.95, green: 0.95, blue: 1.0))
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                                    )
                                                
                                                
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
                                            
                                            
                                            ZStack {
                                                
                                                Rectangle()
                                                    .fill(Color.black)
                                                    .offset(x: 6, y: 6)
                                                
                                                
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
                            Button(action: {
                                elementListState.reset(with: [])
                                onNext()
                            }) {
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
                        
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        
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

    private func resetCurrentState() {

        currentCells = originalCellsState.getCells()
        
        elementListState.hardReset(with: availableElements)
        updateLayout()
    }

    private func updateCurrentCells(_ newCells: [any DataStructureCell]) {
        currentCells = newCells.map { cell in
            var copy = (cell as! BasicCell).deepCopy()
            copy.position = cell.position
            return copy
        }
        updateLayout()
    }

    private var shouldDisableNextButton: Bool {
        
        if isCompleted {
            return false
        }
        
        return true
    }

    private func moveToNextStep() {
        
        if isCompleted {
            currentGuideStep += 1
            renderCycle = UUID()
        }
    }

    private func calculateAutoPlayInterval(comment: String?) -> TimeInterval {
        guard let comment = comment else { return 3.0 }  
        
        
        let baseInterval: TimeInterval = 2.0
        
        
        let additionalTime = TimeInterval(comment.count) * 0.05
        
        
        return min(max(baseInterval + additionalTime, 2.0), 7.0)
    }

    
    private func resetDroppedElementsForCurrentStep() {
        
        if let elements = availableElements {
            elementListState.reset(with: elements)
        }
    }

    
    private func initializeList() {
        elementListState.reset(with: availableElements)
    }
}


struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

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