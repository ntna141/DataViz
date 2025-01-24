import SwiftUI

// Protocol for layout strategies
protocol DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell]
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection]) -> [ConnectionDisplayState]
}

// Layout configuration
struct LayoutConfig {
    static let cellRadius: CGFloat = 24
    static let horizontalSpacing: CGFloat = 30
    static let verticalSpacing: CGFloat = 30
    
    static var cellDiameter: CGFloat { cellRadius * 2 }
}

// Linked list layout strategy
struct LinkedListLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        // Calculate total width needed
        let totalWidth = CGFloat(cells.count) * LayoutConfig.cellDiameter + 
                        CGFloat(cells.count - 1) * LayoutConfig.horizontalSpacing
        
        // Calculate starting position to center the list
        let startX = (frame.width - totalWidth) / 2 + LayoutConfig.cellRadius
        let centerY = frame.height / 2
        
        // Create a copy of cells that we can modify
        var orderedCells = cells
        
        // If there's a head cell, ensure it's first
        if let headIndex = cells.firstIndex(where: { $0.label == "head" }) {
            let headCell = cells[headIndex]
            orderedCells.remove(at: headIndex)
            orderedCells.insert(headCell, at: 0)
        }
        
        // Set positions
        return orderedCells.enumerated().map { index, cell in
            var mutableCell = cell
            mutableCell.position = CGPoint(
                x: startX + CGFloat(index) * (LayoutConfig.cellDiameter + LayoutConfig.horizontalSpacing),
                y: centerY
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection]) -> [ConnectionDisplayState] {
        connections.compactMap { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId }) else {
                return nil
            }
            
            // Create display state with actual points
            var displayState = (connection as? BasicConnection)?.displayState ?? 
                             ConnectionDisplayState(
                                fromPoint: .zero,
                                toPoint: .zero,
                                label: connection.label,
                                isHighlighted: connection.isHighlighted,
                                style: connection.style,
                                visualStyle: connection.isHighlighted ? .highlighted : .standard
                             )
            
            // Update points based on cell positions
            displayState = ConnectionDisplayState(
                fromPoint: fromCell.position,
                toPoint: toCell.position,
                label: displayState.label,
                isHighlighted: displayState.isHighlighted,
                style: displayState.style,
                visualStyle: displayState.visualStyle
            )
            
            return displayState
        }
    }
}

// Binary tree layout strategy
struct BinaryTreeLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        let levels = Int(log2(Double(cells.count))) + 1
        let totalHeight = CGFloat(levels - 1) * (LayoutConfig.cellDiameter + LayoutConfig.verticalSpacing)
        let startY = (frame.height - totalHeight) / 2 + LayoutConfig.cellRadius
        
        return cells.enumerated().map { index, cell in
            var mutableCell = cell
            let level = Int(floor(log2(Double(index + 1))))
            let nodesInLevel = pow(2.0, Double(level))
            let position = Double(index + 1) - pow(2.0, Double(level))
            
            // Calculate horizontal spacing for this level
            let levelWidth = nodesInLevel * Double(LayoutConfig.cellDiameter) + 
                           (nodesInLevel - 1) * Double(LayoutConfig.horizontalSpacing)
            let levelStartX = (Double(frame.width) - levelWidth) / 2 + Double(LayoutConfig.cellRadius)
            let x = levelStartX + position * (Double(LayoutConfig.cellDiameter) + Double(LayoutConfig.horizontalSpacing))
            
            mutableCell.position = CGPoint(
                x: x,
                y: startY + CGFloat(level) * (LayoutConfig.cellDiameter + LayoutConfig.verticalSpacing)
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection]) -> [ConnectionDisplayState] {
        // Similar to linked list but with curved connections
        connections.compactMap { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId }) else {
                return nil
            }
            
            var displayState = (connection as? BasicConnection)?.displayState ?? 
                             ConnectionDisplayState(
                                fromPoint: .zero,
                                toPoint: .zero,
                                label: connection.label,
                                isHighlighted: connection.isHighlighted,
                                style: .curved, // Use curved style for tree connections
                                visualStyle: connection.isHighlighted ? .highlighted : .standard
                             )
            
            displayState = ConnectionDisplayState(
                fromPoint: fromCell.position,
                toPoint: toCell.position,
                label: displayState.label,
                isHighlighted: displayState.isHighlighted,
                style: displayState.style,
                visualStyle: displayState.visualStyle
            )
            
            return displayState
        }
    }
}

// Array layout strategy
struct ArrayLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        let totalWidth = CGFloat(cells.count) * LayoutConfig.cellDiameter + 
                        CGFloat(cells.count - 1) * LayoutConfig.horizontalSpacing
        let startX = (frame.width - totalWidth) / 2 + LayoutConfig.cellRadius
        let centerY = frame.height / 2
        
        return cells.enumerated().map { index, cell in
            var mutableCell = cell
            mutableCell.position = CGPoint(
                x: startX + CGFloat(index) * (LayoutConfig.cellDiameter + LayoutConfig.horizontalSpacing),
                y: centerY
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection]) -> [ConnectionDisplayState] {
        // Arrays typically don't have connections, but implement for completeness
        connections.compactMap { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId }) else {
                return nil
            }
            
            var displayState = (connection as? BasicConnection)?.displayState ?? 
                             ConnectionDisplayState(
                                fromPoint: .zero,
                                toPoint: .zero,
                                label: connection.label,
                                isHighlighted: connection.isHighlighted,
                                style: connection.style,
                                visualStyle: connection.isHighlighted ? .highlighted : .standard
                             )
            
            displayState = ConnectionDisplayState(
                fromPoint: fromCell.position,
                toPoint: toCell.position,
                label: displayState.label,
                isHighlighted: displayState.isHighlighted,
                style: displayState.style,
                visualStyle: displayState.visualStyle
            )
            
            return displayState
        }
    }
}

// Layout manager that coordinates between different layout strategies
class DataStructureLayoutManager {
    private var layoutStrategy: DataStructureLayoutStrategy
    
    init(layoutType: DataStructureLayoutType) {
        self.layoutStrategy = Self.createStrategy(for: layoutType)
    }
    
    func updateLayout(cells: [any DataStructureCell], connections: [any DataStructureConnection], in frame: CGRect) -> (cells: [any DataStructureCell], connectionStates: [ConnectionDisplayState]) {
        let layoutCells = layoutStrategy.calculateLayout(cells: cells, in: frame)
        let connectionStates = layoutStrategy.updateConnectionPoints(cells: layoutCells, connections: connections)
        return (layoutCells, connectionStates)
    }
    
    func setLayoutType(_ type: DataStructureLayoutType) {
        layoutStrategy = Self.createStrategy(for: type)
    }
    
    private static func createStrategy(for type: DataStructureLayoutType) -> DataStructureLayoutStrategy {
        switch type {
        case .linkedList:
            return LinkedListLayoutStrategy()
        case .binaryTree:
            return BinaryTreeLayoutStrategy()
        case .array:
            return ArrayLayoutStrategy()
        }
    }
}

// Layout types
enum DataStructureLayoutType: String {
    case linkedList = "linkedList"
    case binaryTree = "binaryTree"
    case array = "array"
} 