import SwiftUI

struct ArrowView: View {
    let arrow: Arrow
    let fromPosition: CGPoint
    let toPosition: CGPoint
    
    var body: some View {
        Canvas { context, size in
            let path = createArrowPath()
            
            context.stroke(
                path,
                with: .color(arrow.isHighlighted ? .yellow : .black),
                lineWidth: arrow.isHighlighted ? 3 : 2
            )
            
            // Draw arrowhead
            let arrowhead = createArrowhead()
            context.fill(arrowhead, with: .color(arrow.isHighlighted ? .yellow : .black))
            
            // Draw label if exists
            if let label = arrow.label {
                let midPoint = getMidPoint()
                context.draw(Text(label).font(.caption), at: midPoint)
            }
        }
    }
    
    private func createArrowPath() -> Path {
        var path = Path()
        path.move(to: fromPosition)
        
        switch arrow.style {
        case .straight:
            path.addLine(to: toPosition)
        case .curved(let controlPoint):
            path.addQuadCurve(to: toPosition, control: controlPoint)
        case .dashed:
            path.addLine(to: toPosition)
            // Add dash pattern
        }
        
        return path
    }
    
    private func createArrowhead() -> Path {
        // Implementation for arrow head
        Path()
    }
    
    private func getMidPoint() -> CGPoint {
        CGPoint(
            x: (fromPosition.x + toPosition.x) / 2,
            y: (fromPosition.y + toPosition.y) / 2
        )
    }
} 