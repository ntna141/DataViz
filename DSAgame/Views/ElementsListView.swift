import SwiftUI

struct ElementsListView: View {
    @ObservedObject var elementListState: ElementListState
    let dragState: (element: String, location: CGPoint)?
    let isOverElementList: Bool
    let onDragStarted: (String, CGPoint) -> Void
    let onDragChanged: (DragGesture.Value, CGRect) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let geometryFrame: CGRect
    let cellSize: CGFloat
    
    var body: some View {
        ZStack {       
            
            Rectangle()
                .fill(Color.black)
                .offset(x: 6, y: 6)
            
            
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
            
            
            HStack(spacing: cellSize * 0.2) {
                if elementListState.currentList.isEmpty {
                    createDropHint()
                } else {
                    ForEach(Array(elementListState.currentList.enumerated()), id: \.offset) { index, element in
                        createDraggableElement(for: element)
                    }
                }
            }
            .padding(.horizontal, cellSize * 0.2)
        }
        .frame(width: calculateListWidth(), height: cellSize * 1.5)
        .overlay(
            GeometryReader { geometry in
                Color.clear.onAppear {
                }
            }
        )
    }
    
    private func calculateListWidth() -> CGFloat {
        if elementListState.currentList.isEmpty {
            return cellSize * 3 
        } else {
            return min(
                (CGFloat(elementListState.currentList.count) * cellSize) + 
                (CGFloat(elementListState.currentList.count - 1) * (cellSize * 0.5)) + 
                (cellSize * 0.4), 
                UIScreen.main.bounds.width * 0.8 
            )
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

