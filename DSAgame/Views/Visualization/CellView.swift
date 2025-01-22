import SwiftUI

struct CellView: View {
    let cell: Cell
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(cell.isHighlighted ? Color.yellow.opacity(0.3) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(cell.isHighlighted ? Color.yellow : Color.black, lineWidth: 2)
                )
            
            Text(cell.value)
                .font(.system(size: 20, weight: .medium))
            
            if let label = cell.label {
                Text(label)
                    .font(.caption)
                    .padding(4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(4)
                    .position(labelPosition)
            }
        }
        .frame(width: cell.size.width, height: cell.size.height)
        .position(cell.position)
    }
    
    private var labelPosition: CGPoint {
        let offset: CGFloat = 25
        switch cell.labelPosition {
        case .top:
            return CGPoint(x: cell.size.width/2, y: -offset)
        case .bottom:
            return CGPoint(x: cell.size.width/2, y: cell.size.height + offset)
        case .left:
            return CGPoint(x: -offset, y: cell.size.height/2)
        case .right:
            return CGPoint(x: cell.size.width + offset, y: cell.size.height/2)
        }
    }
} 