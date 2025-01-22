import SwiftUI

struct DataStructureExampleView: View {
    // Example linked list
    let linkedListNodes = [
        DSNode(value: "1", position: CGPoint(x: 100, y: 100)),
        DSNode(value: "2", position: CGPoint(x: 200, y: 100)),
        DSNode(value: "3", isHighlighted: true, position: CGPoint(x: 300, y: 100)),
        DSNode(value: "4", position: CGPoint(x: 400, y: 100))
    ]
    
    var linkedListConnections: [DSConnection] {
        var connections: [DSConnection] = []
        for i in 0..<(linkedListNodes.count - 1) {
            connections.append(
                DSConnection(
                    from: linkedListNodes[i].id,
                    to: linkedListNodes[i + 1].id,
                    label: i == 1 ? "next" : nil,
                    isHighlighted: i == 1
                )
            )
        }
        return connections
    }
    
    // Example binary tree
    let treeNodes = [
        DSNode(value: "5", position: CGPoint(x: 250, y: 300)),
        DSNode(value: "3", position: CGPoint(x: 150, y: 400)),
        DSNode(value: "7", isHighlighted: true, position: CGPoint(x: 350, y: 400)),
        DSNode(value: "1", position: CGPoint(x: 100, y: 500)),
        DSNode(value: "4", position: CGPoint(x: 200, y: 500)),
        DSNode(value: "6", position: CGPoint(x: 300, y: 500)),
        DSNode(value: "8", position: CGPoint(x: 400, y: 500))
    ]
    
    var treeConnections: [DSConnection] {
        [
            DSConnection(from: treeNodes[0].id, to: treeNodes[1].id, label: "left"),
            DSConnection(from: treeNodes[0].id, to: treeNodes[2].id, label: "right", isHighlighted: true),
            DSConnection(from: treeNodes[1].id, to: treeNodes[3].id),
            DSConnection(from: treeNodes[1].id, to: treeNodes[4].id),
            DSConnection(from: treeNodes[2].id, to: treeNodes[5].id),
            DSConnection(from: treeNodes[2].id, to: treeNodes[6].id)
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
                    connections: linkedListConnections
                )
                .frame(height: 150)
            }
            
            VStack(alignment: .leading) {
                Text("Binary Tree")
                    .font(.headline)
                    .padding(.leading)
                
                DataStructureView(
                    nodes: treeNodes,
                    connections: treeConnections
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
