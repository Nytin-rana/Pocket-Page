import SwiftUI
import SwiftData

struct NotebookView: View {
    var notebook: Notebook
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Action states
    @State private var showRenameAlert = false
    @State private var newNotebookName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // --- Custom Navigation Header (Matches 20260706_130235.jpg) ---
            HStack(spacing: 16) {
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                // Notebook Title
                Text(notebook.title) // Assuming your model uses .title or .name
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Three Dots Action Popup Menu (Matches 20260706_130258.jpg)
                Menu {
                    Button(action: {
                        favtoggle()
                    }) {
                        Label("Favorite", systemImage: notebook.isFavorite ? "star.fill" :"star")
                    }
                    Button(action: {
                        newNotebookName = notebook.title
                        showRenameAlert = true
                    }) {
                        Label("Rename notebook", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        deleteNotebook()
                    }) {
                        Label("Delete notebook", systemImage: "trash")
                    }
                    
                    Button(role: .destructive, action: {
                        clearChatHistory()
                    }) {
                        Label("Delete chat history", systemImage: "ellipsis.bubble")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90)) // Vertically oriented dots
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color.black) // Matches dark interface background
            
            // --- Bottom Content Tabs (From source 2) ---
            TabView {
                ChatView(notebook: notebook)
                    .tabItem {
                        VStack {
                            Image(systemName: "bubble.left.and.bubble.right").environment(\.symbolVariants, .none)
                            Text("Chat").font(.caption)
                        }
                    }
                SourceView(notebook: notebook) 
                    .tabItem {
                        VStack {
                            Image(systemName: "folder").environment(\.symbolVariants, .none) 
                            Text("Sources").font(.caption) 
                        }
                    }
                ManageView(notebook: notebook) 
                    .tabItem { Label("Manage", systemImage: "square.and.pencil") } 
            }
            // Optional styling to match the unified floating tab bar style in screenshots
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(red: 20/255, green: 20/255, blue: 25/255, alpha: 1)
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .navigationBarHidden(true) // Hide the default navigation header bar
        .background(Color.black.ignoresSafeArea())
        // Rename Dialog Implementation
        .alert("Rename Notebook", isPresented: $showRenameAlert) {
            TextField("Notebook Name", text: $newNotebookName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !newNotebookName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    notebook.title = newNotebookName
                    try? modelContext.save()
                }
            }
        }
    }
    
    // MARK: - Logic Functions
    private func favtoggle() {
        // Toggles the favorite boolean state
        notebook.isFavorite.toggle()
        
        // Explicitly persist the change to SwiftData
        try? modelContext.save()
    }
    
    private func deleteNotebook() {
        modelContext.delete(notebook)
        try? modelContext.save()
        dismiss() // Pop back to main dashboard
    }
    
    private func clearChatHistory() {
        // Clears referenced chat sessions associated with SwiftData model
        notebook.chatSessions.removeAll()
        try? modelContext.save()
        
        // Triggers UI refresh safely by reloading context parameters
        modelContext.processPendingChanges()
    }
}
