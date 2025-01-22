import CoreData
import SwiftUI

public class ProgressionManager: ObservableObject {
    @Published public private(set) var levels: [Level] = []
    @Published public private(set) var totalStars: Int = 0
    @Published public private(set) var dailyChallenge: Level?
    @Published public private(set) var lastDailyChallengeDate: Date?
    
    private let coreDataManager = CoreDataManager.shared
    private let dailyChallengeKey = "dailyChallenge"
    private let lastDailyChallengeKey = "lastDailyChallengeDate"
    private let saveKey = "game_progress"
    
    public init() {
        loadLevels()
        setupDailyChallenge()
    }
    
    private func loadLevels() {
        let fetchRequest = NSFetchRequest<LevelEntity>(entityName: "LevelEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LevelEntity.number, ascending: true)]
        
        do {
            let levelEntities = try coreDataManager.context.fetch(fetchRequest)
            if levelEntities.isEmpty {
                createInitialLevels()
            } else {
                self.levels = levelEntities.map { convertLevelEntityToLevel($0) }
            }
            updateTotalStars()
        } catch {
            print("Error loading levels: \(error)")
        }
    }
    
    private func convertLevelEntityToLevel(_ entity: LevelEntity) -> Level {
        let questions = (entity.questions?.allObjects as? [QuestionEntity])?.compactMap { questionEntity -> Question? in
            guard let type = QuestionType(rawValue: questionEntity.type ?? ""),
                  let title = questionEntity.title,
                  let description = questionEntity.desc,
                  let difficulty = Question.Difficulty(rawValue: Int(questionEntity.difficulty)) else {
                return nil
            }
            
            var question = Question(type: type, title: title, description: description, difficulty: difficulty)
            question.isCompleted = questionEntity.isCompleted
            question.stars = Int(questionEntity.stars)
            question.bestTime = questionEntity.bestTime
            question.attempts = Int(questionEntity.attempts)
            return question
        } ?? []
        
        return Level(
            number: Int(entity.number),
            topic: entity.topic ?? "",
            description: entity.desc ?? "",
            requiredStars: Int(entity.requiredStars),
            questions: questions
        )
    }
    
    private func createInitialLevels() {
        let context = coreDataManager.context
        
        // Create mock array level
        let levelEntity = LevelEntity(context: context)
        levelEntity.uuid = UUID()
        levelEntity.number = 1
        levelEntity.topic = "Array Basics"
        levelEntity.desc = "Learn the fundamentals of array data structure"
        levelEntity.requiredStars = 0
        levelEntity.isUnlocked = true
        
        // Create questions for the level
        for questionType in QuestionType.allCases {
            let questionEntity = QuestionEntity(context: context)
            questionEntity.uuid = UUID()
            questionEntity.type = questionType.rawValue
            questionEntity.title = "Array \(questionType.rawValue.capitalized)"
            questionEntity.desc = "Practice array operations with \(questionType.description)"
            questionEntity.difficulty = 1
            questionEntity.isCompleted = false
            questionEntity.stars = 0
            questionEntity.attempts = 0
            questionEntity.level = levelEntity
        }
        
        try? context.save()
        loadLevels()
    }
    
    private func updateTotalStars() {
        totalStars = levels.reduce(0) { $0 + $1.totalStars }
    }
    
    public func completeQuestion(inLevel levelNumber: Int, ofType type: QuestionType, withStars stars: Int, time: TimeInterval) {
        let context = coreDataManager.context
        
        let levelFetch = NSFetchRequest<LevelEntity>(entityName: "LevelEntity")
        levelFetch.predicate = NSPredicate(format: "number == %d", levelNumber)
        
        do {
            guard let levelEntity = try context.fetch(levelFetch).first,
                  let questions = levelEntity.questions?.allObjects as? [QuestionEntity],
                  let questionEntity = questions.first(where: { $0.type == type.rawValue }) else {
                return
            }
            
            // Create attempt record
            let attemptEntity = QuestionAttemptEntity(context: context)
            attemptEntity.uuid = UUID()
            attemptEntity.date = Date()
            attemptEntity.stars = Int16(stars)
            attemptEntity.timeSpent = time
            attemptEntity.question = questionEntity
            
            // Update question stats
            questionEntity.isCompleted = true
            questionEntity.stars = max(questionEntity.stars, Int16(stars))
            questionEntity.attempts += 1
            questionEntity.bestTime = questionEntity.bestTime.map { min($0, time) } ?? time
            
            try context.save()
            loadLevels()
        } catch {
            print("Error completing question: \(error)")
        }
    }
    
    public func getQuestionHistory(forLevel level: Int, type: QuestionType) -> [QuestionAttempt] {
        let fetchRequest = NSFetchRequest<QuestionAttemptEntity>(entityName: "QuestionAttemptEntity")
        fetchRequest.predicate = NSPredicate(format: "question.level.number == %d AND question.type == %@", level, type.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \QuestionAttemptEntity.date, ascending: false)]
        
        do {
            let attempts = try coreDataManager.context.fetch(fetchRequest)
            return attempts.map { QuestionAttempt(entity: $0) }
        } catch {
            print("Error fetching history: \(error)")
            return []
        }
    }
    
    private func setupDailyChallenge() {
        // Generate daily challenge
        self.dailyChallenge = generateDailyChallenge()
        
        // Load daily challenge
        if let savedDate = UserDefaults.standard.object(forKey: lastDailyChallengeKey) as? Date {
            self.lastDailyChallengeDate = savedDate
            if Calendar.current.isDateInToday(savedDate),
               let challengeData = UserDefaults.standard.data(forKey: dailyChallengeKey),
               let challenge = try? JSONDecoder().decode(Level.self, from: challengeData) {
                self.dailyChallenge = challenge
            } else {
                generateNewDailyChallenge()
            }
        } else {
            generateNewDailyChallenge()
        }
    }
    
    private func generateNewDailyChallenge() {
        // Create a new daily challenge with random questions from different levels
        let questions = QuestionType.allCases.map { type in
            let randomLevel = levels.randomElement() ?? levels[0]
            return randomLevel.questions[type] ?? Question(type: type,
                                                         title: "Daily \(type.rawValue.capitalized)",
                                                         description: "Complete the daily challenge",
                                                         difficulty: .medium)
        }
        
        dailyChallenge = Level(number: 0,
                             topic: "Daily Challenge",
                             description: "Complete all question types for bonus rewards",
                             requiredStars: 0,
                             questions: questions)
        
        lastDailyChallengeDate = Date()
        
        if let encoded = try? JSONEncoder().encode(dailyChallenge) {
            UserDefaults.standard.set(encoded, forKey: dailyChallengeKey)
            UserDefaults.standard.set(lastDailyChallengeDate, forKey: lastDailyChallengeKey)
        }
    }
    
    private func generateDailyChallenge() -> Level? {
        // Implement daily challenge generation logic
        return nil
    }
    
    private func fetchLevel(number: Int) -> LevelEntity? {
        // Implement logic to fetch a level entity from Core Data
        return nil
    }
} 