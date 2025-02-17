import Foundation
import SwiftUI

class VisualizationManager {
    static let shared = VisualizationManager()
    
    private init() {}
    
    // Create a visualization question from JSON data
    func createVisualization(from jsonData: LevelData.Question) -> VisualizationQuestion? {
        guard let visualization = jsonData.visualization else {
            print("No visualization data found")
            return nil
        }
        
        // Create code lines
        let codeLines = visualization.code.enumerated().map { index, line in
            CodeLine(
                number: index + 1,
                content: line,
                syntaxTokens: SyntaxParser.parse(line)
            )
        }
        
        // Create steps
        let steps = visualization.steps.map { stepData -> VisualizationStep in
            // Convert nodes to cells
            let cells = stepData.nodes.map { node -> BasicCell in
                BasicCell(
                    id: UUID().uuidString,
                    value: node.value,
                    isHighlighted: node.isHighlighted ?? false,
                    label: node.label,
                    row: node.row ?? 0
                )
            }
            
            // Convert connections
            let connections = (stepData.connections ?? []).map { connection -> BasicConnection in
                let fromId = connection.from.map { cells[$0].id } ?? UUID().uuidString
                let toId = connection.to.map { cells[$0].id } ?? UUID().uuidString
                
                return BasicConnection(
                    id: UUID().uuidString,
                    fromCellId: fromId,
                    toCellId: toId,
                    fromLabel: connection.fromLabel,
                    toLabel: connection.toLabel,
                    label: connection.label,
                    isHighlighted: connection.isHighlighted ?? false,
                    style: ConnectionStyle(rawValue: connection.style ?? "straight") ?? .straight
                )
            }
            
            return VisualizationStep(
                codeHighlightedLine: stepData.lineNumber,
                lineComment: stepData.comment,
                hint: stepData.hint,
                cells: cells,
                connections: connections,
                userInputRequired: stepData.userInputRequired,
                availableElements: stepData.availableElements,
                isMultipleChoice: stepData.isMultipleChoice ?? false,
                multipleChoiceAnswers: stepData.multipleChoiceAnswers ?? [],
                multipleChoiceCorrectAnswer: stepData.multipleChoiceCorrectAnswer ?? ""
            )
        }
        
        return VisualizationQuestion(
            title: jsonData.title,
            description: jsonData.description,
            hint: jsonData.hint ?? "",
            review: jsonData.review ?? "",
            code: codeLines,
            steps: steps,
            initialCells: [],
            initialConnections: [],
            layoutType: DataStructureLayoutType(rawValue: visualization.dataStructureType) ?? .linkedList
        )
    }
} 
