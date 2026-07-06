import SwiftUI
import UniformTypeIdentifiers
import Foundation
import SwiftData
import PDFKit

struct AddFileBottomSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    // Explicitly pass the active Notebook reference to append data directly
    let notebook: Notebook
    
    @State private var selectedFiles: [URL] = []
    
    // File Picker Presentation States
    @State private var isFilePickerPresented = false
    @State private var allowedTypes: [UTType] = [.data]
    
    private let backgroundColor = Color(red: 19/255, green: 24/255, blue: 30/255)
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
                            Text("Add files")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.white)
                            
                            Text("to your notebook")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(accentGreen)
                        }
                        .multilineTextAlignment(.center)
                        
                        // --- Selected Files Preview ---
                        if !selectedFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Selected Files:")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(secondaryTextColor)
                                
                                ForEach(selectedFiles, id: \.self) { url in
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperclip")
                                            .font(.system(size: 12))
                                        Text(url.lastPathComponent)
                                            .lineLimit(1)
                                    }
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // --- Section Subtitle ---
                        Text("Choose Files")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                        
                        // --- Option Buttons Stack ---
                        VStack(spacing: 12) {
                            sourceButton(title: "PDF", iconName: "doc.viewfinder", type: .pdf) {
                                triggerPicker(for: [.pdf])
                            }
                            
                            sourceButton(title: "Markdown File", iconName: "doc.text", type: .plainText) {
                                triggerPicker(for: [.plainText, .text])
                            }
                            
                            sourceButton(title: "Other Files", iconName: "folder", type: .data) {
                                triggerPicker(for: [.data, .content])
                            }
                        }
                        
                        Spacer()
                        
                        // --- Add File Capsule Action Button ---
                        Button(action: {
                            appendFilesToNotebook()
                        }) {
                            Text("Add File")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(accentGreen)
                                .clipShape(Capsule())
                        }
                        .disabled(selectedFiles.isEmpty)
                        .opacity(selectedFiles.isEmpty ? 0.5 : 1.0)
                        
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
    
    func extractTextFromPDF(at url: URL) -> String {
        guard let document = PDFDocument(url: url) else { return "" }
        var completeText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let pageText = page.string {
                completeText += pageText + "\n"
            }
        }
        return completeText
    }
    
    // MARK: - Ingestion Logic For Existing Notebook Reference
    private func appendFilesToNotebook() {
        for url in selectedFiles {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            
            var extractedText = ""
            let fileExtension = url.pathExtension.lowercased()
            
            if fileExtension == "pdf" {
                extractedText = extractTextFromPDF(at: url)
            } else {
                if let textContent = try? String(contentsOf: url, encoding: .utf8) {
                    extractedText = textContent
                }
            }
            
            let documentSource = DocumentSource(
                fileName: url.lastPathComponent,
                fileType: fileExtension,
                rawTextContent: extractedText
            )
            
            // Append right into the targeted entity directly
            notebook.sources.append(documentSource)
            
            let textToIngest = extractedText
            let targetNotebookId = notebook.id
            
            Task {
                await VectorDatabase.shared.ingestDocument(
                    text: textToIngest,
                    notebookId: targetNotebookId,
                    sourceId: documentSource.id
                )
            }
        }
        
        try? modelContext.save()
        isPresented = false
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
        case .pdf: return types.contains(.pdf)
        case .text: return types.contains(.plainText) || types.contains(.text)
        case .image: return false
        case .any: return true
        }
    }
}
