import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct CreateNotebookBottomSheet: View {
    @Binding var isPresented: Bool
    @State private var notebookName: String = ""
    @State private var selectedFiles: [URL] = []
    
    // File Picker Presentation States
    @State private var isFilePickerPresented = false
    @State private var allowedTypes: [UTType] = [.data]
    
    private let backgroundColor = Color(red: 19/255, green: 24/255, blue: 30/255)
    private let fieldBackgroundColor = Color(red: 28/255, green: 34/255, blue: 42/255)
    private let strokeColor = Color(red: 44/255, green: 53/255, blue: 61/255)
    private let inputGlowColor = Color(red: 56/255, green: 81/255, blue: 181/255)
    private let accentGreen = Color(red: 61/255, green: 220/255, blue: 132/255)
    private let secondaryTextColor = Color(red: 154/255, green: 160/255, blue: 166/255)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- Header Close Button ---
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                            .padding(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // --- Title Header ---
                        VStack(spacing: 4) {
                            Text("Create a notebook")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.white)
                            
                            Text("from your notes")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(accentGreen)
                        }
                        .multilineTextAlignment(.center)
                        
                        // --- Notebook Name Input Field ---
                        TextField("Enter Notebook Name", text: $notebookName, prompt: Text("Notebook name").foregroundColor(secondaryTextColor))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(fieldBackgroundColor)
                            .cornerRadius(12)
                        
                        // --- Selected Files Preview ---
                        if !selectedFiles.isEmpty {
                            Text("Selected: \(selectedFiles.count) file(s)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                        }
                        
                        // --- Section Subtitle ---
                        Text("Choose Files")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                        
                        // --- Option Buttons Stack ---
                        VStack(spacing: 12) {
                            sourceButton(title: "PDF", iconName: "doc.pdf", type: .pdf) {
                                triggerPicker(for: [.pdf])
                            }
                            
                            sourceButton(title: "Markdown File", iconName: "doc.text.desktop", type: .plainText) {
                                triggerPicker(for: [.plainText, .text])
                            }
                            
                            sourceButton(title: "Other Files", iconName: "folder", type: .data) {
                                triggerPicker(for: [.data, .content])
                            }
                        }
                        
                        Spacer()
                        
                        // --- Create Notebook Capsule Button ---
                        Button(action: {
                            // TODO: Add your notebook creation logic here
                            print("Notebook \(notebookName) created with \(selectedFiles.count) files.")
                            isPresented = false
                        }) {
                            Text("Create Notebook")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black) // Black text
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(accentGreen) // Green background
                                .clipShape(Capsule())
                        }
                        .disabled(notebookName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedFiles.isEmpty)
                        .opacity((notebookName.isEmpty || selectedFiles.isEmpty) ? 0.5 : 1.0)
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                let filtered = urls.filter { isValidFile($0, types: allowedTypes) }
                self.selectedFiles.append(contentsOf: filtered)
            case .failure(let error):
                print("Error picking document: \(error.localizedDescription)")
            }
        }
    }
    
    @ViewBuilder
    private func sourceButton(title: String, iconName: String, type: UTType, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName).font(.system(size: 18))
                Text(title).font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(
                Capsule()
                    .stroke(type == .pdf || type == .plainText ? strokeColor : inputGlowColor, lineWidth: 1.5)
            )
        }
    }

    private func triggerPicker(for types: [UTType]) {
        self.allowedTypes = types
        self.isFilePickerPresented = true
    }
    
    private func isValidFile(_ url: URL, types: [UTType]) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard let filter = TypeFilter.extended(type: ext) else { return false }
        
        if types.contains(.data) || types.contains(.content) { return true }
        
        switch filter {
        case .pdf:
            return types.contains(.pdf)
        case .text:
            return types.contains(.plainText) || types.contains(.text)
        case .image:
            return false
        case .any:
            return true
        }
    }
}

struct TypeFilter {
    enum Element: Equatable, CaseIterable {
        case pdf, text, image, any
        
        var utType: UTType? {
            switch self {
            case .pdf: return .pdf
            case .text: return .plainText
            case .image: return .image
            case .any: return nil
            }
        }
    }
    
    static func extended(type extensionName: String) -> Element? {
        switch extensionName {
        case "pdf": return .pdf
        case "txt", "markdown", "md": return .text
        case "jpg", "png", "jpeg", "gif", "heif": return .image
        default: return .any
        }
    }
}

#Preview {
    CreateNotebookBottomSheet(isPresented: .constant(true))
}
