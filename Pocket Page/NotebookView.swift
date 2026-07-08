import SwiftUI
import SwiftData

struct NotebookView: View {
    var notebook: Notebook
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showRenameAlert = false
    @State private var newNotebookName = ""
    
    @State private var exportURL: URL? = nil
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Text(notebook.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
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
                        
                        Button(action: {
                            saveNotebookToJSON()
                        }) {
                            Label("Save notebook", systemImage: "square.and.arrow.up")
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
                            .rotationEffect(.degrees(90))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color.appBackground)
                
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
                .onAppear {
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor(Color.appBackground)
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
        .navigationBarHidden(true)
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
        .sheet(isPresented: $showShareSheet) {
            if let exportURL = exportURL {
                ShareSheetView(activityItems: [exportURL])
            }
        }
    }
    
    private func favtoggle() {
        notebook.isFavorite.toggle()
        try? modelContext.save()
    }
    
    private func saveNotebookToJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        cleanUpTemporaryFile()
        
        do {
            let data = try encoder.encode(notebook)
            let safeTitle = notebook.title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
            let filename = "\(safeTitle)_notebook.json"
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let targetURL = documentsDirectory.appendingPathComponent(filename)
            try data.write(to: targetURL)
            
            DispatchQueue.main.async {
                self.exportURL = targetURL
                self.showShareSheet = true
            }
        } catch {
            print("Failed to serialize and save data payload: \(error.localizedDescription)")
        }
    }
    
    private func cleanUpTemporaryFile() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
            self.exportURL = nil
        }
    }
    
    private func deleteNotebook() {
        modelContext.delete(notebook)
        try? modelContext.save()
        dismiss()
    }
    
    private func clearChatHistory() {
        notebook.chatSessions.removeAll()
        try? modelContext.save()
        modelContext.processPendingChanges()
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
