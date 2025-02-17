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
                                .padding(.top, 50)
                            
                            Spacer()
                                .frame(height: 20)
                            
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
                                        .font(.system(.body, design: .monospaced))
                                        .multilineTextAlignment(.center)
                                        .padding(30)
                                }
                            }
                            .frame(minHeight: 300, maxHeight: geometry.size.height * 0.6)
                            .frame(maxWidth: .infinity)
                            
                            Spacer()
                                .frame(height: 40)
                            
                            // Buttons with restored retro styling
                            VStack(spacing: 25) {
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
                                    Button(action: onNext) {
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
                                
                                ZStack {
                                    // Shadow
                                    Text("Back to Map")
                                        .font(.system(.title3, design: .monospaced))
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .offset(x: 6, y: 6)
                                    
                                    // Main button
                                    Button(action: onBackToMap) {
                                        Text("Back to Map")
                                            .font(.system(.title3, design: .monospaced))
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.white)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.black, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 50)
                        }
                        .padding(40)
                    }
                    .padding(10)
                    .padding(.top, 20)
                    .frame(width: geometry.size.width > 768 ? geometry.size.width / 2 : geometry.size.width * 0.9)
                    .frame(height: geometry.size.width > 768 ? geometry.size.height * 0.95 : nil)
                    .frame(minHeight: geometry.size.height * 0.85)
                    .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

