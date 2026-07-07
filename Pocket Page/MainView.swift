import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    
    @Query(sort: \Notebook.createdAt, order: .reverse) private var notebooks: [Notebook]
    
    @State private var selectedFilter = "Recent"
    let filters = ["Recent", "Favourite", "All"]
    
    @State private var showingCreateNotebook = false
    
    // Search states
    @State private var isSearching = false
    @State private var searchQuery = ""

    // Dynamic filtering AND Search computed property
    private var filteredNotebooks: [Notebook] {
        
        var baseNotebooks: [Notebook]
        switch selectedFilter {
        case "Recent":
            baseNotebooks = Array(notebooks.prefix(5))
        case "Favourite":
            baseNotebooks = notebooks.filter { $0.isFavorite }
        default:
            baseNotebooks = notebooks
        }
        
        
        let cleanedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedQuery.isEmpty {
            return baseNotebooks.filter {
                $0.title.localizedCaseInsensitiveContains(cleanedQuery)
            }
        }
        
        return baseNotebooks
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 26/255, green: 30/255, blue: 36/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // --- Dynamic Header Bar ---
                    if isSearching {
                        // Inline Search Field Layer
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.4))
                                
                                TextField("Search notebooks...", text: $searchQuery)
                                    .foregroundColor(.white)
                                    .tint(.white)
                                    .autocorrectionDisabled()
                                
                                if !searchQuery.isEmpty {
                                    Button(action: { searchQuery = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            
                            .liquidGlassCapsule()
                            
                            Button("Cancel") {
                                withAnimation(.spring(duration: 0.25)) {
                                    searchQuery = ""
                                    isSearching = false
                                }
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    } else {
                        // Standard Branding Header Layer
                        HStack {
#if DEBUG

(Group {
    if UIImage(named: "logo") != nil {
        Image("logo")
            .resizable()
            .scaledToFit()
    } else {
        Image(systemName: "book.closed")
            .resizable()
            .scaledToFit()
    }
})
    .frame(width: 44, height: 44)
    .foregroundColor(.white)
#else
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.white)
#endif
                            
                            Text("Pocket Page")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(duration: 0.25)) {
                                    isSearching = true
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 44, height: 44, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Filter Horizontal Scroll Segment
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 50) {
                            ForEach(filters, id: \.self) { filter in
                                Text(filter)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(selectedFilter == filter ? Color.white.opacity(0.15) : Color.clear)
                                    )
                                    .foregroundColor(.white)
                                    .onTapGesture {
                                        selectedFilter = filter
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    
                    // List Cards ScrollView
                    ScrollView {
                        VStack(spacing: 14) {
                            if filteredNotebooks.isEmpty {
                                Text(emptyStateMessage)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 60)
                            } else {
                                ForEach(filteredNotebooks) { notebook in
                                    NavigationLink(destination: NotebookView(notebook: notebook)) {
                                        HStack(spacing: 16) {
                                            Text("📚")
                                                .font(.system(size: 28))
                                                .frame(width: 45, height: 45)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(notebook.title)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Text("\(notebook.sources.count) sources • \(formattedDate(notebook.createdAt))")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            
                                            Spacer()
                                            
                                            if notebook.isFavorite {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.yellow.opacity(0.8))
                                                    .padding(.trailing, 4)
                                            }
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .background(Color.white.opacity(0.03))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            showingCreateNotebook = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Create New")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .frame(height: 56)
                            .contentShape(Capsule())
                        }
                        .liquidGlassCapsule()
                    }
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showingCreateNotebook) {
                CreateNotebookBottomSheet(isPresented: $showingCreateNotebook)
            }
        }
    }
    
    
    private var emptyStateMessage: String {
        if !searchQuery.isEmpty {
            return "No matching notebooks found for\n\"\(searchQuery)\""
        }
        
        switch selectedFilter {
        case "Recent":
            return "No recent notebooks.\nTap 'Create New' below to start!"
        case "Favourite":
            return "No favorite notebooks yet.\nMark them as favorites inside your notebooks!"
        default:
            return "No notebooks created yet.\nTap 'Create New' below to start!"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            
            .padding(.horizontal, 4)
            .background(
                ZStack {
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.06), .white.opacity(0.01)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white.opacity(0.25), location: 0),
                                .init(color: .clear, location: 0.5),
                                .init(color: .white.opacity(0.05), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
    }
}
extension View {
    func liquidGlassCircle() -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: 9999))
    }
    
    func liquidGlassCapsule() -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: 28))
    }
}

#Preview {
    
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

    
    let container = try! ModelContainer(
        for: Notebook.self,
        configurations: configuration
    )

   
    MainView()
        .modelContainer(container)
}

