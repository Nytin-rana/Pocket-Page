import SwiftUI
import SwiftData

struct ChatView: View {
    var notebook: Notebook
    @State var text: String = ""
    @State private var isThinking: Bool = false
    
    private let qwenLoader = LocalQwenLoader()
    
    private var currentSession: ChatSession? {
        notebook.chatSessions.first
    }
    
    func onSendAction(text1: String) {
        guard let session = currentSession else { return }
        
        let userMessage = ChatMessage(text: text1, isUser: true)
        session.messages.append(userMessage)
        
        withAnimation(.easeInOut) {
            isThinking = true
        }
        
        Task {
            do {
                let relevantChunks = await VectorDatabase.shared.search(query: text1, notebookId: notebook.id)
                let contextString = relevantChunks.joined(separator: "\n\n")
                let systemPrompt = "You are a helpful notebook assistant. Use the following source context to answer the question if applicable.\n\nContext:\n\(contextString)"
                
                try await qwenLoader.loadModel()
                let aiMessage = ChatMessage(text: "", isUser: false)
                
                await MainActor.run {
                    session.messages.append(aiMessage)
                    isThinking = false
                }
                
                _ = try await qwenLoader.generateResponse(
                    prompt: text1,
                    systemPrompt: systemPrompt
                ) { token in
                    aiMessage.text += token
                }
                
                try? aiMessage.modelContext?.save()
                
            } catch {
                print("Error generating response: \(error.localizedDescription)")
                await MainActor.run {
                    isThinking = false
                    let errorMessage = ChatMessage(text: "Sorry, I encountered an error processing that request.", isUser: false)
                    session.messages.append(errorMessage)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let messages = currentSession?.messages, !messages.isEmpty {
                                ForEach(messages.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { msg in
                                    HStack {
                                        if msg.isUser { Spacer() }
                                        
                                        Text(msg.text)
                                            .font(.system(.body, design: .rounded))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            // Dynamic background box depending on message author
                                            .background(msg.isUser ? Color.blue.opacity(0.8) : Color.white.opacity(0.03))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                        
                                        if !msg.isUser { Spacer() }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                
                                if isThinking {
                                    HStack {
                                        ThinkingAnimationView()
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.03))
                                            .cornerRadius(12)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    .transition(.opacity)
                                }
                                
                            } else {
                                ContentUnavailableView(
                                    "Ask your Notebook",
                                    systemImage: "bubble.left.and.bubble.right",
                                    description: Text("Type a question below to start chatting with your imported sources.")
                                )
                                .foregroundColor(.gray)
                                .padding(.top, 100)
                            }
                        }
                        .padding()
                    }
                    
                    // Input Pill Bar Container
                    HStack(spacing: 12) {
                        HStack {
                            TextField("", text: $text, prompt:
                                Text("Ask a question")
                                    .foregroundColor(Color(.systemGray))
                            )
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .disabled(isThinking)
                            
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
                        .liquidGlassCapsule()
                        
                        Button(action: {
                            guard !text.isEmpty else { return }
                            onSendAction(text1: text)
                            text = ""
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(text.isEmpty || isThinking ? Color(.systemGray) : .white)
                                .frame(width: 48, height: 48)
                                .background(Color(.systemGray6).opacity(0.4))
                                .clipShape(Circle())
                        }
                        .liquidGlassCircle()
                        .disabled(text.isEmpty || isThinking)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.appBackground)
                }
            }
            .navigationTitle(notebook.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                do {
                    try await qwenLoader.loadModel()
                } catch {
                    print("Failed to pre-load model layers: \(error)")
                }
            }
        }
    }
}

// MARK: - Thinking Animation Subview
struct ThinkingAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 7, height: 7)
                    .scaleEffect(isAnimating ? 1.0 : 0.4)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
