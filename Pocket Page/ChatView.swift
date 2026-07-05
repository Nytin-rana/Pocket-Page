//
//  ChatView.swift
//  Pocket Page
//
//  Created by Nytin Rana on 05/07/26.
//

import SwiftUI

struct ChatView: View {
    @State var text: String = ""
    func onSendAction(text1 : String) {
        print(text1)
    }
    var body: some View {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(1...30, id: \.self) { index in
                                Text("Row Item \(index)")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Safe Area Inset")
                    // ⬇️ This makes the element sticky at the bottom
                    HStack(spacing: 12) {
                                // Main Pill Input Field Container
                                HStack {
                                    TextField("", text: $text, prompt:
                                        Text("Ask a question")
                                            .foregroundColor(Color(.systemGray))
                                    )
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    
                                    // Subtle clear button or status indicator at the trailing edge
                                    if !text.isEmpty {
                                        Button(action: { text = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Color(.systemGray2))
                                                .padding(.trailing, 12)
                                        }
                                    }
                                }
                                .background(Color(.systemGray6).opacity(0.4))
                                .clipShape(Capsule())
                                
                                // Circular Return/Action Button
                                Button(action: {
                                    guard !text.isEmpty else { return }
                                    onSendAction(text1 :text)
                                    text = "" // Clear after trigger
                                }) {
                                    Image(systemName: "arrow.turn.up.left")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(text.isEmpty ? Color(.systemGray) : .white)
                                        .frame(width: 48, height: 48)
                                        .background(Color(.systemGray6).opacity(0.4))
                                        .clipShape(Circle())
                                }
                                .disabled(text.isEmpty) // Keeps styling dimmed when empty
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.edgesIgnoringSafeArea(.bottom)) // Grounding dark UI wrapper
                        }
                    }
                            
                            
                        
                        
                    
                
            }
        
    


#Preview {
    ChatView()
}
