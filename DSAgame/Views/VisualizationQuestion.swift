    private func moveToNextStep() {
        print("\n=== Moving to Next Step ===")
        
        let nextIndex = currentStepIndex + 1
        guard nextIndex < question.steps.count else { return }
        
        let nextStep = question.steps[nextIndex]
        
        print("\nCurrent step cells:")
        for (i, cell) in currentStep.cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
        
        print("\nNext step cells:")
        for (i, cell) in nextStep.cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
        
        currentStepIndex = nextIndex
        currentStep = nextStep
        
        print("\nMoved to step \(nextIndex)")
        print("Updated cells:")
        for (i, cell) in currentStep.cells.enumerated() {
            print("Cell \(i): value='\(cell.value)', label=\(cell.label ?? "none")")
        }
    }
    
    private func setValue(_ value: String, forCellAtIndex index: Int) {
        guard index < currentStep.cells.count else { return }
        var newCells = currentStep.cells
        var updatedCell = newCells[index]
        updatedCell.setValue(value)
        newCells[index] = updatedCell
        currentStep.cells = newCells
    }

    var body: some View {
        // Right half - Data structure view
        DataStructureView(
            layoutType: question.layoutType,
            cells: currentStep.cells,
            connections: currentStep.connections,
            availableElements: currentStep.userInputRequired ? currentStep.availableElements : [],
            onElementDropped: { value, index in
                if currentStep.userInputRequired {
                    setValue(value, forCellAtIndex: index)
                }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .trailing)
    }
} 