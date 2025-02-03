import SwiftUI

// Protocol for layout strategies
protocol DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell]
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection], scale: CGFloat) -> [ConnectionDisplayState]
}

// Layout configuration
struct LayoutConfig {
    static let cellRadius: CGFloat = 24
    static let horizontalSpacing: CGFloat = 30
    static let verticalSpacing: CGFloat = 30
    static let elementListHeight: CGFloat = 100 // Height reserved for element list
    
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
        // Adjust vertical position to account for element list
        let startX = (frame.width - totalWidth) / 2 + LayoutConfig.cellRadius
        let centerY = (frame.height - LayoutConfig.elementListHeight) / 2 - (frame.height * 0.1)
        
        // Use cells directly without reordering
        return cells.enumerated().map { index, cell in
            var mutableCell = cell
            mutableCell.position = CGPoint(
                x: startX + CGFloat(index) * (LayoutConfig.cellDiameter + LayoutConfig.horizontalSpacing),
                y: centerY
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(
        cells: [any DataStructureCell],
        connections: [any DataStructureConnection],
        scale: CGFloat
    ) -> [ConnectionDisplayState] {
        connections.map { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId })
            else {
                return ConnectionDisplayState(
                    fromPoint: .zero,
                    toPoint: .zero,
                    label: connection.label,
                    isHighlighted: connection.isHighlighted,
                    style: connection.style,
                    visualStyle: connection.isHighlighted ? .highlighted(scale: scale) : .standard(scale: scale),
                    scale: scale
                )
            }
            
            // For linked lists, we want the arrow to point from left to right
            // Calculate points on the edge of the circles
            let fromPoint = CGPoint(
                x: fromCell.position.x + LayoutConfig.cellRadius,
                y: fromCell.position.y
            )
            
            let toPoint = CGPoint(
                x: toCell.position.x - LayoutConfig.cellRadius,
                y: toCell.position.y
            )
            
            return ConnectionDisplayState(
                fromPoint: fromPoint,
                toPoint: toPoint,
                label: connection.label,
                isHighlighted: connection.isHighlighted,
                style: connection.style,
                visualStyle: connection.isHighlighted ? .highlighted(scale: scale) : .standard(scale: scale),
                scale: scale
            )
        }
    }
}

// Binary tree layout strategy
struct BinaryTreeLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        // Calculate tree dimensions
        let levels = Int(log2(Double(cells.count))) + 1
        let maxNodesInBottomLevel = pow(2.0, Double(levels - 1))
        let totalWidth = maxNodesInBottomLevel * Double(LayoutConfig.cellDiameter) + 
                        (maxNodesInBottomLevel - 1) * Double(LayoutConfig.horizontalSpacing)
        let totalHeight = CGFloat(levels - 1) * (LayoutConfig.cellDiameter + LayoutConfig.verticalSpacing)
        
        // Center the tree both horizontally and vertically
        // Account for element list in vertical centering
        let startY = ((frame.height - LayoutConfig.elementListHeight) - totalHeight) / 2 + 
                    LayoutConfig.cellRadius - (frame.height * 0.1)
        
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
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection], scale: CGFloat) -> [ConnectionDisplayState] {
        // Similar to linked list but with curved connections
        connections.compactMap { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId }) else {
                return nil
            }
            
            // Calculate edge points
            let angle = atan2(toCell.position.y - fromCell.position.y,
                            toCell.position.x - fromCell.position.x)
            
            // Calculate points on the edge of the circles
            let fromPoint = CGPoint(
                x: fromCell.position.x + LayoutConfig.cellRadius * cos(angle),
                y: fromCell.position.y + LayoutConfig.cellRadius * sin(angle)
            )
            
            let toPoint = CGPoint(
                x: toCell.position.x - LayoutConfig.cellRadius * cos(angle),
                y: toCell.position.y - LayoutConfig.cellRadius * sin(angle)
            )
            
            var displayState = (connection as? BasicConnection)?.displayState ?? 
                             ConnectionDisplayState(
                                fromPoint: fromPoint,
                                toPoint: toPoint,
                                label: connection.label,
                                isHighlighted: connection.isHighlighted,
                                style: .curved, // Use curved style for tree connections
                                visualStyle: connection.isHighlighted ? .highlighted(scale: scale) : .standard(scale: scale),
                                scale: scale
                             )
            
            displayState = ConnectionDisplayState(
                fromPoint: fromPoint,
                toPoint: toPoint,
                label: displayState.label,
                isHighlighted: displayState.isHighlighted,
                style: displayState.style,
                visualStyle: displayState.visualStyle,
                scale: scale
            )
            
            return displayState
        }
    }
}

// Array layout strategy
struct ArrayLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        // Calculate total width needed
        let totalWidth = CGFloat(cells.count) * LayoutConfig.cellDiameter + 
                        CGFloat(cells.count - 1) * LayoutConfig.horizontalSpacing
        
        // Center horizontally and vertically, accounting for element list
        let startX = (frame.width - totalWidth) / 2 + LayoutConfig.cellRadius
        let centerY = (frame.height - LayoutConfig.elementListHeight) / 2 - (frame.height * 0.1)
        
        return cells.enumerated().map { index, cell in
            var mutableCell = cell
            mutableCell.position = CGPoint(
                x: startX + CGFloat(index) * (LayoutConfig.cellDiameter + LayoutConfig.horizontalSpacing),
                y: centerY
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection], scale: CGFloat) -> [ConnectionDisplayState] {
        // Arrays typically don't have connections, but implement for completeness
        connections.compactMap { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId }) else {
                return nil
            }
            
            // Calculate edge points
            let angle = atan2(toCell.position.y - fromCell.position.y,
                            toCell.position.x - fromCell.position.x)
            
            // Calculate points on the edge of the circles
            let fromPoint = CGPoint(
                x: fromCell.position.x + LayoutConfig.cellRadius * cos(angle),
                y: fromCell.position.y + LayoutConfig.cellRadius * sin(angle)
            )
            
            let toPoint = CGPoint(
                x: toCell.position.x - LayoutConfig.cellRadius * cos(angle),
                y: toCell.position.y - LayoutConfig.cellRadius * sin(angle)
            )
            
            var displayState = (connection as? BasicConnection)?.displayState ?? 
                             ConnectionDisplayState(
                                fromPoint: fromPoint,
                                toPoint: toPoint,
                                label: connection.label,
                                isHighlighted: connection.isHighlighted,
                                style: connection.style,
                                visualStyle: connection.isHighlighted ? .highlighted(scale: scale) : .standard(scale: scale),
                                scale: scale
                             )
            
            displayState = ConnectionDisplayState(
                fromPoint: fromPoint,
                toPoint: toPoint,
                label: displayState.label,
                isHighlighted: displayState.isHighlighted,
                style: displayState.style,
                visualStyle: displayState.visualStyle,
                scale: scale
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
    
    func updateLayout(
        cells: [any DataStructureCell],
        connections: [any DataStructureConnection],
        in frame: CGRect,
        scale: CGFloat
    ) -> ([any DataStructureCell], [ConnectionDisplayState]) {
        
        // Ensure we have a valid frame
        guard frame.width > 0, frame.height > 0 else {
            return (cells, [])
        }
        
        let layoutCells = layoutStrategy.calculateLayout(cells: cells, in: frame)
        
        let connectionStates = layoutStrategy.updateConnectionPoints(
            cells: layoutCells,
            connections: connections,
            scale: scale
        )
        
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