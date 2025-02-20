import Foundation

class GameProgressionManager {
    static let shared = GameProgressionManager()
    private var levelData: LevelData?
    private var completedQuestions: Set<String> = []
    private var completedLevels: Set<Int> = []
    
    private init() {
        loadLevelData()
    }
    
    private func loadLevelData() {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.levelData = try decoder.decode(LevelData.self, from: data)
        } catch {
            print("Error loading level data: \(error)")
        }
    }
    
    func getLevels() -> [LevelData.Level] {
        return levelData?.levels ?? []
    }
    
    func getQuestions(forLevel levelNumber: Int) -> [LevelData.Question] {
        return levelData?.levels.first(where: { $0.number == levelNumber })?.questions ?? []
    }
    
    func markQuestionCompleted(_ questionId: String) {
        completedQuestions.insert(questionId)
        
        
        if let levelNumber = Int(questionId.split(separator: "-").first ?? "") {
            checkAndUpdateLevelCompletion(levelNumber)
        }
    }
    
    func isQuestionCompleted(_ questionId: String) -> Bool {
        return completedQuestions.contains(questionId) || 
               isLevelCompleted(Int(questionId.split(separator: "-").first ?? "") ?? 0)
    }
    
    private func checkAndUpdateLevelCompletion(_ levelNumber: Int) {
        let questions = getQuestions(forLevel: levelNumber)
        
        
        let allCompleted = questions.enumerated().allSatisfy { index, _ in
            completedQuestions.contains("\(levelNumber)-\(index)")
        }
        
        if allCompleted {
            completedLevels.insert(levelNumber)
        }
    }
    
    func isLevelCompleted(_ levelNumber: Int) -> Bool {
        return completedLevels.contains(levelNumber)
    }
    
    func resetProgress() {
        completedQuestions.removeAll()
        completedLevels.removeAll()
    }
} 
