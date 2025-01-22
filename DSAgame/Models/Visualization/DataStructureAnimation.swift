import Foundation

enum DataStructureAnimation {
    case highlight(cellIds: [UUID])
    case move(cellId: UUID, to: CGPoint)
    case connect(from: UUID, to: UUID)
    case disconnect(from: UUID, to: UUID)
} 