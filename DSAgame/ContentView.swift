//
//  ContentView.swift
//  DSAgame
//
//  Created by Anh Nguyen on 1/21/25.
//

import SwiftUI

// MARK: - Main View
struct ContentView: View {
    @EnvironmentObject var progressionManager: ProgressionManager
    @State private var selectedLevel: Level?
    
    private var overallProgress: Double {
        let completedQuestions = progressionManager.levels.reduce(0) { sum, level in
            sum + level.questions.values.filter { $0.isCompleted }.count
        }
        let totalQuestions = progressionManager.levels.count * QuestionType.allCases.count
        return Double(completedQuestions) / Double(totalQuestions)
    }
    
    var body: some View {
        NavigationView {
            List {
                ProgressSection(progress: overallProgress,
                              totalStars: progressionManager.totalStars)
                
                if let dailyChallenge = progressionManager.dailyChallenge {
                    Section(header: Text("Daily Challenge")) {
                        LevelRow(level: dailyChallenge)
                            .onTapGesture {
                                selectedLevel = dailyChallenge
                            }
                    }
                }
                
                Section(header: Text("Levels")) {
                    ForEach(progressionManager.levels) { level in
                        LevelRow(level: level)
                            .onTapGesture {
                                selectedLevel = level
                            }
                    }
                }
            }
            .navigationTitle("DSA Game")
            .sheet(item: $selectedLevel) { level in
                LevelDetailView(level: level)
            }
        }
    }
}

// MARK: - Supporting Views
struct ProgressSection: View {
    let progress: Double
    let totalStars: Int
    
    var body: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Overall Progress: \(Int(progress * 100))%")
                ProgressView(value: progress)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(totalStars) Stars Collected")
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }
}

struct LevelTypeSection: View {
    let title: String
    let type: LevelType
    let levels: [Level]
    
    var body: some View {
        Section(header: Text(title)) {
            ForEach(levels) { level in
                LevelRow(level: level)
            }
        }
    }
}

struct LevelRow: View {
    let level: Level
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Level \(level.number): \(level.topic)")
                    .font(.headline)
                Text(level.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Show progress for all question types
                ForEach(Array(level.questions.values.sorted(by: { $0.type.rawValue < $1.type.rawValue }))) { question in
                    HStack {
                        Image(systemName: question.type.icon)
                        if question.isCompleted {
                            ForEach(0..<question.stars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            if !level.isUnlocked {
                HStack {
                    Text("\(level.requiredStars)★")
                    Image(systemName: "lock.fill")
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(level.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ProgressionManager()) // Provide the environment object for preview
}
