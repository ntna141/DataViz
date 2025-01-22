import SwiftUI

class ArrayViewModel: DataStructureViewModel {
    func initialize(values: [String], startPosition: CGPoint = CGPoint(x: 100, y: 100)) {
        cells = values.enumerated().map { index, value in
            Cell(
                value: value,
                position: CGPoint(
                    x: startPosition.x + CGFloat(index) * 70,
                    y: startPosition.y
                )
            )
        }
    }
    
    func highlightIndex(_ index: Int) {
        guard index < cells.count else { return }
        highlight(cellIds: [cells[index].id])
    }
} 