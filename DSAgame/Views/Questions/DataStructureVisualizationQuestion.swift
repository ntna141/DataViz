import SwiftUI

struct DataStructureVisualizationQuestion: View {
    @ObservedObject var viewModel: QuestionViewModel
    @StateObject private var arrayVM = ArrayViewModel()
    
    var body: some View {
        VStack {
            // Visualization Area
            DataStructureView(viewModel: arrayVM)
                .frame(height: 300)
            
            // Instructions
            Text("Find the maximum value in the array")
                .font(.headline)
                .padding()
            
            // Interactive Controls
            HStack {
                ForEach(0..<arrayVM.cells.count, id: \.self) { index in
                    Button("\(index)") {
                        handleSelection(index)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if viewModel.isComplete {
                VStack {
                    Text("Correct! 🎉")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Time: \(String(format: "%.1fs", viewModel.elapsedTime))")
                }
                .padding()
            }
        }
        .onAppear {
            setupQuestion()
        }
    }
    
    private func setupQuestion() {
        // Initialize with random values
        let values = (0..<6).map { _ in
            String(Int.random(in: 1...99))
        }
        arrayVM.initialize(values: values)
        viewModel.startTimer()
    }
    
    private func handleSelection(_ index: Int) {
        arrayVM.highlightIndex(index)
        
        // Check if selected the maximum value
        if let maxValue = arrayVM.cells.map({ Int($0.value) ?? 0 }).max(),
           let selectedValue = Int(arrayVM.cells[index].value),
           maxValue == selectedValue {
            viewModel.complete(stars: 3) // Award full stars for correct answer
        }
    }
} 