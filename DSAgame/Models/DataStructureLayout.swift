import SwiftUI


protocol DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell]
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection], scale: CGFloat) -> [ConnectionDisplayState]
}


struct LayoutConfig {
    static let cellRadius: CGFloat = 24
    static let horizontalSpacing: CGFloat = 30
    static let verticalSpacing: CGFloat = 30
    static let elementListHeight: CGFloat = 100 
    
    static var cellDiameter: CGFloat { cellRadius * 2 }
}


struct LinkedListLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        
        let totalWidth = CGFloat(cells.count) * LayoutConfig.cellDiameter + 
                        CGFloat(cells.count - 1) * LayoutConfig.horizontalSpacing
        
        
        
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


struct BinaryTreeLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        
        let levels = Int(log2(Double(cells.count))) + 1
        let maxNodesInBottomLevel = pow(2.0, Double(levels - 1))
        let totalWidth = maxNodesInBottomLevel * Double(LayoutConfig.cellDiameter) + 
                        (maxNodesInBottomLevel - 1) * Double(LayoutConfig.horizontalSpacing)
        
        
        let verticalSpacingMultiplier: CGFloat = 1.7  
        let totalHeight = CGFloat(levels - 1) * (LayoutConfig.cellDiameter + 
                                                LayoutConfig.verticalSpacing * verticalSpacingMultiplier)
        
        
        
        let startY = ((frame.height - LayoutConfig.elementListHeight) - totalHeight) / 2 + 
                    LayoutConfig.cellRadius - (frame.height * 0.1)
        
        return cells.enumerated().map { index, cell in
            var mutableCell = cell
            let level = Int(floor(log2(Double(index + 1))))
            let nodesInLevel = pow(2.0, Double(level))
            let position = Double(index + 1) - pow(2.0, Double(level))
            
            
            let levelWidth = nodesInLevel * Double(LayoutConfig.cellDiameter) + 
                           (nodesInLevel - 1) * Double(LayoutConfig.horizontalSpacing)
            let levelStartX = (Double(frame.width) - levelWidth) / 2 + Double(LayoutConfig.cellRadius)
            let x = levelStartX + position * (Double(LayoutConfig.cellDiameter) + Double(LayoutConfig.horizontalSpacing))
            
            mutableCell.position = CGPoint(
                x: x,
                y: startY + CGFloat(level) * (LayoutConfig.cellDiameter + 
                                            LayoutConfig.verticalSpacing * verticalSpacingMultiplier)
            )
            return mutableCell
        }
    }
    
    func updateConnectionPoints(cells: [any DataStructureCell], connections: [any DataStructureConnection], scale: CGFloat) -> [ConnectionDisplayState] {
        
        connections.compactMap { connection in
            guard let fromCell = cells.first(where: { $0.id == connection.fromCellId }),
                  let toCell = cells.first(where: { $0.id == connection.toCellId }) else {
                return nil
            }
            
            
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
            
            var displayState = (connection as? BasicConnection)?.displayState ?? 
                             ConnectionDisplayState(
                                fromPoint: fromPoint,
                                toPoint: toPoint,
                                label: connection.label,
                                isHighlighted: connection.isHighlighted,
                                style: .curved, 
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


struct ArrayLayoutStrategy: DataStructureLayoutStrategy {
    func calculateLayout(cells: [any DataStructureCell], in frame: CGRect) -> [any DataStructureCell] {
        guard !cells.isEmpty else { return [] }
        
        
        let rowGroups = Dictionary(grouping: cells) { $0.row }
        let rowCount = rowGroups.count
        
        
        let availableHeight = frame.height - LayoutConfig.elementListHeight
        let verticalSpacing = (LayoutConfig.verticalSpacing * 2) + 50 
        let startY = (availableHeight - (CGFloat(rowCount - 1) * verticalSpacing)) / 2
        
        return cells.map { cell in
            var mutableCell = cell
            let rowIndex = cell.row
            let cellsInRow = rowGroups[rowIndex]?.count ?? 1
            
            
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
        return connections.compactMap { connection in
            
            let fromCell: (any DataStructureCell)?
            let toCell: (any DataStructureCell)?
            
            if let fromLabel = connection.fromLabel {
                fromCell = cells.first(where: { $0.label == fromLabel })
            } else {
                fromCell = cells.first(where: { $0.id == connection.fromCellId })
            }
            
            if let toLabel = connection.toLabel {
                toCell = cells.first(where: { $0.label == toLabel })
            } else {
                toCell = cells.first(where: { $0.id == connection.toCellId })
            }
            
            guard let fromCell = fromCell, let toCell = toCell else {
                return nil
            }
            
            
            let angle = atan2(fromCell.position.y - toCell.position.y,
                             fromCell.position.x - toCell.position.x)
            
            
            let verticalThreshold = CGFloat.pi / 4  
            let isMoreVertical = abs(angle) > verticalThreshold

            let offset = isMoreVertical ? 
                LayoutConfig.cellRadius * 0.2 :  
                LayoutConfig.cellRadius * 0.2        

            let fromPoint = CGPoint(
                x: fromCell.position.x + offset * cos(angle),
                y: fromCell.position.y + offset * sin(angle)
            )

            let toPoint = CGPoint(
                x: toCell.position.x - offset * cos(angle),
                y: toCell.position.y - offset * sin(angle)
            )
            
            
            let isDifferentRows = fromCell.row != toCell.row
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


enum DataStructureLayoutType: String {
    case linkedList = "linkedList"
    case binaryTree = "binaryTree"
    case array = "array"
} 