import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item] // Kept for SwiftData schema integration
    
    // Sample hardcoded data matching 20260705_095827.jpg for rendering
    let sampleCards = [
        CardData(title: "TAFL", details: "7 sources • May 17, 2026", emoji: "🤖", buttonIcon: "wand.and.stars"),
        CardData(title: "Java OOP and Programmin...", details: "1 source • May 15, 2026", emoji: "☕️", buttonIcon: "wand.and.stars"),
        CardData(title: "UHVPE", details: "3 sources • May 6, 2026", emoji: "🧘‍♂️", buttonIcon: "play.fill")
    ]
    
    @State private var selectedFilter = "Recent"
    let filters = ["Recent", "Favourite", "All"]
    
    @State private var showingCreateNotebook = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color matched exactly to the image
                Color(red: 26/255, green: 30/255, blue: 36/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        Image("logo") // Fallback text/system view if asset is missing
                            .resizable()
                            .scaledToFit()
                            .frame(height: 35)
                        
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
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
                            ForEach(sampleCards) { card in
                                HStack(spacing: 16) {
                                    // Emoji Container
                                    Text(card.emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 45, height: 45)
                                    
                                    // Text Content
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(card.title)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(card.details)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    // Action Button
                                    Button(action: {}) {
                                        Image(systemName: card.buttonIcon)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Bottom Sticky Action Bar
                    HStack(spacing: 16) {
                        
                        
                        
                        // "Create New" Button with liquid glass capsule background
                        Button(action: {
                            showingCreateNotebook = true
                            print("btn pressed")
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
            // Sheet to present CreateNotebookBottomSheet when showingCreateNotebook is true
            .sheet(isPresented: $showingCreateNotebook) {
                CreateNotebookBottomSheet(isPresented: $showingCreateNotebook)
            }
        }
    }
}

// MARK: - Supporting Data Structures
struct CardData: Identifiable {
    let id = UUID()
    let title: String
    let details: String
    let emoji: String
    let buttonIcon: String
}

// MARK: - Liquid Glass Modifier and View Extension
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ).allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.25), location: 0),
                                .init(color: Color.clear, location: 0.5),
                                .init(color: Color.white.opacity(0.05), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    ).allowsHitTesting(false)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
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
    MainView()
        .modelContainer(for: Item.self, inMemory: true)
}
