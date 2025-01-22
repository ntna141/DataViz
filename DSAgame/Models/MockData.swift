import Foundation

extension Level {
    static var mockArrayLevel: Level {
        Level(
            number: 1,
            topic: "Array Basics",
            description: "Learn the fundamentals of array data structure",
            requiredStars: 0,
            questions: [
                Question(
                    type: .visualization,
                    title: "Find Maximum",
                    description: "Find the maximum value in the array by selecting the correct element",
                    difficulty: .easy
                ),
                Question(
                    type: .coding,
                    title: "Array Insertion",
                    description: "Write code to insert an element at a specific position",
                    difficulty: .medium
                ),
                Question(
                    type: .multipleChoice,
                    title: "Time Complexity",
                    description: "What is the time complexity of array insertion?",
                    difficulty: .easy
                ),
                Question(
                    type: .analysis,
                    title: "Space Analysis",
                    description: "Analyze the space complexity of different array operations",
                    difficulty: .medium
                )
            ]
        )
    }
} 