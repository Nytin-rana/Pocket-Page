import SwiftUI
import SwiftData

struct ManageView: View {
    var notebook: Notebook
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddFiles: Bool = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                if notebook.sources.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No sources attached to this notebook.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(notebook.sources) { source in
                            HStack {
                                Image(systemName: source.fileType == "pdf" ? "doc.viewfinder" : "doc.text")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(source.fileName)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    deleteSource(source)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .listRowBackground(Color.white.opacity(0.03))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                }
                
                Button(action: {
                    showingAddFiles = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add Sources")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 56)
                    .contentShape(Capsule())
                }
                .liquidGlassCapsule()
                .padding(24)
                .sheet(isPresented: $showingAddFiles) {
                    AddFileBottomSheet(isPresented: $showingAddFiles, notebook: notebook)
                }
            }
        }
    }
    
    private func deleteSource(_ source: DocumentSource) {
        if let index = notebook.sources.firstIndex(where: { $0.id == source.id }) {
            notebook.sources.remove(at: index)
            modelContext.delete(source)
            try? modelContext.save()
        }
    }
}
