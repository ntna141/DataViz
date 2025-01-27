import SwiftUI

private struct CellSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 48 // Default cell diameter
}

extension EnvironmentValues {
    var cellSize: CGFloat {
        get { self[CellSizeKey.self] }
        set { self[CellSizeKey.self] = newValue }
    }
}

class CellSizeManager: ObservableObject {
    @Published var size: CGFloat = 48
    
    func updateSize(for viewSize: CGSize) {
        // Base size on the smaller dimension, with a reasonable range
        let dimension = min(viewSize.width, viewSize.height)
        size = min(max(dimension * 0.1, 40), 80) // Min 40, Max 80
    }
} 