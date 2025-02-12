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
            let angle = atan2(fromCell.position.y - toCell.position.y,
                            fromCell.position.x - toCell.position.x)
            
            // Calculate points on the edge of the circles
            let fromPoint = CGPoint(
                x: toCell.position.x + LayoutConfig.cellRadius * cos(angle),
                y: toCell.position.y + LayoutConfig.cellRadius * sin(angle)
            )
            
            let toPoint = CGPoint(
                x: fromCell.position.x - LayoutConfig.cellRadius * cos(angle),
                y: fromCell.position.y - LayoutConfig.cellRadius * sin(angle)
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
        
        // Group cells by their row
        let rowGroups = Dictionary(grouping: cells) { $0.row }
        let rowCount = rowGroups.count
        
        // Calculate vertical spacing between rows
        let availableHeight = frame.height - LayoutConfig.elementListHeight
        let verticalSpacing = (LayoutConfig.verticalSpacing * 2) + 40 // Increase vertical spacing between rows by additional 20 points
        let startY = (availableHeight - (CGFloat(rowCount - 1) * verticalSpacing)) / 2
        
        return cells.map { cell in
            var mutableCell = cell
            let rowIndex = cell.row
            let cellsInRow = rowGroups[rowIndex]?.count ?? 1
            
            // Calculate horizontal position within row
            let totalWidth = CGFloat(cellsInRow) * LayoutConfig.cellDiameter + 
                           CGFloat(cellsInRow - 1) * LayoutConfig.horizontalSpacing
            let startX = (frame.width - totalWidth) / 2 + LayoutConfig.cellRadius
            let cellIndex = rowGroups[rowIndex]?.firstIndex(where: { $0.id == cell.id }) ?? 0
            
            mutableCell.position = CGPoint(
                x: startX + CGFloat(cellIndex) * (LayoutConfig.cellDiameter + LayoutConfig.horizontalSpacing),
                y: startY + CGFloat(rowIndex) * verticalSpacing
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection], scale: CGFloat) -> [ConnectionDisplayState] {
        print("\nUpdating connection points for array layout:")
        return connections.compactMap { connection in
            // Support both index-based and label-based connections
            let fromCell: (any DataStructureCell)?
            let toCell: (any DataStructureCell)?
            
            if let fromLabel = connection.fromLabel {
                fromCell = cells.first(where: { $0.label == fromLabel })
                print("Looking for fromLabel: \(fromLabel), found: \(fromCell?.label ?? "none")")
            } else {
                fromCell = cells.first(where: { $0.id == connection.fromCellId })
                print("Looking for fromId: \(connection.fromCellId), found: \(fromCell?.id ?? "none")")
            }
            
            if let toLabel = connection.toLabel {
                toCell = cells.first(where: { $0.label == toLabel })
                print("Looking for toLabel: \(toLabel), found: \(toCell?.label ?? "none")")
            } else {
                toCell = cells.first(where: { $0.id == connection.toCellId })
                print("Looking for toId: \(connection.toCellId), found: \(toCell?.id ?? "none")")
            }
            
            guard let fromCell = fromCell, let toCell = toCell else {
                print("⚠️ Failed to find cells for connection")
                print("  - From Cell ID: \(connection.fromCellId)")
                print("  - To Cell ID: \(connection.toCellId)")
                print("  - From Label: \(connection.fromLabel ?? "none")")
                print("  - To Label: \(connection.toLabel ?? "none")")
                print("  - Available Cell IDs: \(cells.map { $0.id }.joined(separator: ", "))")
                print("  - Available Labels: \(cells.compactMap { $0.label }.joined(separator: ", "))")
                return nil
            }
            
            // Calculate connection points from the edges of cells
            let angle = atan2(fromCell.position.y - toCell.position.y,
                            fromCell.position.x - toCell.position.x)
            
            let fromPoint = CGPoint(
                x: toCell.position.x + LayoutConfig.cellRadius * cos(angle),
                y: toCell.position.y + LayoutConfig.cellRadius * sin(angle)
            )
            
            let toPoint = CGPoint(
                x: fromCell.position.x - LayoutConfig.cellRadius * cos(angle),
                y: fromCell.position.y - LayoutConfig.cellRadius * sin(angle)
            )
            
            print("\nCalculated connection points:")
            print("  - From Cell: position (\(fromCell.position.x), \(fromCell.position.y))")
            print("  - To Cell: position (\(toCell.position.x), \(toCell.position.y))")
            print("  - Connection Points: from (\(fromPoint.x), \(fromPoint.y)) to (\(toPoint.x), \(toPoint.y))")
            
            // If cells are in different rows, swap the points
            let isDifferentRows = fromCell.row != toCell.row
            return ConnectionDisplayState(
                fromPoint: isDifferentRows ? toPoint : fromPoint,
                toPoint: isDifferentRows ? fromPoint : toPoint,
                label: connection.label,
                isHighlighted: connection.isHighlighted,
                style: connection.style,
                visualStyle: connection.isHighlighted ? .highlighted(scale: scale) : .standard(scale: scale),
                scale: scale
            )
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