import SwiftUI

class LinkedListViewModel: DataStructureViewModel {
    func initialize(values: [String], startPosition: CGPoint = CGPoint(x: 100, y: 100)) {
        // Create cells
        cells = values.enumerated().map { index, value in
            Cell(
                value: value,
                position: CGPoint(
                    x: startPosition.x + CGFloat(index) * 100,
                    y: startPosition.y
                )
            )
        }
        
        // Create arrows between nodes
        for i in 0..<(cells.count - 1) {
            arrows.append(
                Arrow(from: cells[i].id, to: cells[i + 1].id)
            )
        }
    }
} 