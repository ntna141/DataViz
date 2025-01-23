import SwiftUI

struct DataStructureExampleView: View {
    // Example linked list
    @State private var linkedListNodes = [
        DSNode(value: "1", position: .zero),
        DSNode(value: "2", position: .zero),
        DSNode(value: "3", isHighlighted: true, position: .zero),
        DSNode(value: "4", position: .zero)
    ]
    
    var linkedListConnections: [DSConnection] {
        var connections: [DSConnection] = []
        for i in 0..<(linkedListNodes.count - 1) {
            connections.append(
                DSConnection(
                    from: linkedListNodes[i].id,
                    to: linkedListNodes[i + 1].id,
                    label: i == 1 ? "next" : nil,
                    isHighlighted: i == 1,
                    style: .straight
                )
            )
        }
        return connections
    }
    
    // Example binary tree
    @State private var treeNodes = [
        DSNode(value: "5", position: .zero),
        DSNode(value: "3", position: .zero),
        DSNode(value: "7", isHighlighted: true, position: .zero),
        DSNode(value: "1", position: .zero),
        DSNode(value: "4", position: .zero),
        DSNode(value: "6", position: .zero),
        DSNode(value: "8", position: .zero)
    ]
    
    var treeConnections: [DSConnection] {
        [
            DSConnection(from: treeNodes[0].id, to: treeNodes[1].id, label: "left", style: .curved),
            DSConnection(from: treeNodes[0].id, to: treeNodes[2].id, label: "right", isHighlighted: true, style: .curved),
            DSConnection(from: treeNodes[1].id, to: treeNodes[3].id, style: .curved),
            DSConnection(from: treeNodes[1].id, to: treeNodes[4].id, style: .curved),
            DSConnection(from: treeNodes[2].id, to: treeNodes[5].id, style: .curved),
            DSConnection(from: treeNodes[2].id, to: treeNodes[6].id, style: .curved)
        ]
    }
    
    var body: some View {
        VStack(spacing: 50) {
            Text("Data Structure Examples")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading) {
                Text("Linked List")
                    .font(.headline)
                    .padding(.leading)
                
                DataStructureView(
                    nodes: linkedListNodes,
                    connections: linkedListConnections,
                    layoutType: .linkedList
                )
                .frame(height: 150)
            }
            
            VStack(alignment: .leading) {
                Text("Binary Tree")
                    .font(.headline)
                    .padding(.leading)
                
                DataStructureView(
                    nodes: treeNodes,
                    connections: treeConnections,
                    layoutType: .binaryTree
                )
                .frame(height: 300)
            }
        }
        .padding()
    }
}

#Preview {
    DataStructureExampleView()
} 
