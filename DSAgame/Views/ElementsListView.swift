import SwiftUI

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
        ZStack {       
            // Shadow layer
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
            
            // Main rectangle
            Rectangle()
                .fill(Color(red: isOverElementList ? 0.7 : 0.95, 
                            green: isOverElementList ? 0.7 : 0.95, 
                            blue: isOverElementList ? 0.9 : 1.0))
                .overlay(
                    Rectangle()
                        .stroke(
                            Color(red: 0.2, green: 0.2, blue: 0.2),
                            lineWidth: 2
                        )
                )
                .animation(.easeInOut, value: isOverElementList)
            
            // Content
            HStack(spacing: cellSize * 0.2) {
                let elements = availableElements + droppedElements
                ForEach(elements, id: \.self) { element in
                    createDraggableElement(for: element)
                }
                
                if shouldShowDropHint {
                    createDropHint()
                }
            }
            .padding(.horizontal, cellSize * 0.05)
        }
        .frame(width: calculateListWidth(), height: cellSize * 0.6)
        .overlay(
            GeometryReader { geometry in
                Color.clear.onAppear {
                }
            }
        )
    }
    
    private var shouldShowDropHint: Bool {
        availableElements.isEmpty && droppedElements.isEmpty
    }
    
    private func calculateListWidth() -> CGFloat {
        let elements = availableElements + droppedElements
        if elements.isEmpty {
            return cellSize * 2 // Reduced width for drop hint
        } else {
            return (CGFloat(elements.count) * cellSize) + // elements width
                   (CGFloat(max(0, elements.count - 1))) // spacing between elements
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
            .font(.system(size: cellSize * 0.15))
            .foregroundColor(.gray)
            .opacity(isOverElementList ? 1.0 : 0.8)
            .animation(.easeInOut, value: isOverElementList)
            .frame(width: cellSize * 2)
            .monospaced()
    }
}

