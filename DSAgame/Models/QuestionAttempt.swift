import Foundation

struct QuestionAttempt: Identifiable {
    let id: UUID
    let date: Date
    let stars: Int
    let timeSpent: TimeInterval
    
    init(entity: QuestionAttemptEntity) {
        self.id = entity.uuid ?? UUID()
        self.date = entity.date ?? Date()
        self.stars = Int(entity.stars)
        self.timeSpent = entity.timeSpent
    }
} 