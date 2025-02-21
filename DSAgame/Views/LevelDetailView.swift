import SwiftUI
import GameplayKit

struct ReviewScreen: View {
    let review: String
    let onNext: () -> Void
    let onBackToMap: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack {
                    // Main Card
                    ZStack {
                        // Shadow layer
                        Rectangle()
                            .fill(Color.black)
                            .offset(x: 6, y: 6)
                        
                        // Main background
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                            )
                        
                        // Content
                        VStack(spacing: 30) {
                            Text("Great Job!")
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color.yellow.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.top, 20)
                            
                            Text("""
                                ┌─────┐
                                │ ^ᴗ^ │
                                └─────┘
                                """)
                                .font(.system(size: 30, design: .monospaced))
                                .fontWeight(.bold)
                            
                            // Review text box
                            ScrollView {
                                ZStack {
                                    // Shadow layer
                                    Rectangle()
                                        .fill(Color.black)
                                        .offset(x: 6, y: 6)
                                    
                                    // Main box
                                    Rectangle()
                                        .fill(Color.white)
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 2)
                                        )
                                    
                                    Text(review)
                                        .font(.system(.body, design: .monospaced, weight: .bold))
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(12)
                                        .padding(20)
                                }
                                .padding(40)
                            }
                            .frame(height: geometry.size.height * 0.4)
                            .padding(.top, 30)
                            .padding(.horizontal, 20)
                            
                            Spacer()
                            
                            // Buttons
                            HStack(spacing: 25) {
                                Button(action: onBackToMap) {
                                    ZStack {
                                        // Shadow
                                        Text("Back to Map")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.black)
                                            .offset(x: 6, y: 6)
                                        
                                        // Main button
                                        Text("Back to Map")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: onNext) {
                                    ZStack {
                                        // Shadow
                                        Text("Start Next Question")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .offset(x: 6, y: 6)
                                        
                                        // Main button
                                        Text("Start Next Question")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }
                        .padding(40)
                    }
                    .padding(10)
                    .padding(.top, 5)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width * 0.7 : geometry.size.width * 0.95)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.95 : nil)
                    .frame(minHeight: geometry.size.height * 0.85)
                    .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

