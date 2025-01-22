import SwiftUI

struct DataStructurePlayground: View {
    @StateObject private var arrayVM = ArrayViewModel()
    @StateObject private var linkedListVM = LinkedListViewModel()
    
    var body: some View {
        VStack {
            // Array visualization
            DataStructureView(viewModel: arrayVM)
                .frame(height: 200)
            
            // Linked List visualization
            DataStructureView(viewModel: linkedListVM)
                .frame(height: 200)
            
            // Controls
            HStack {
                Button("Initialize Array") {
                    arrayVM.initialize(values: ["1", "2", "3", "4", "5"])
                }
                
                Button("Initialize Linked List") {
                    linkedListVM.initialize(values: ["A", "B", "C"])
                }
            }
        }
    }
} 