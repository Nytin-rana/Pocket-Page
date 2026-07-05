

import Foundation
import NaturalLanguage
import Accelerate

struct VectorChunk: Identifiable, Codable {
    let id: UUID
    let notebookId: UUID
    let sourceId: UUID
    let text: String
    let embedding: [Double]
}

actor VectorDatabase {
    static let shared = VectorDatabase()
    private var vectorStore: [VectorChunk] = []
    private let embedder = NLEmbedding.sentenceEmbedding(for: .english)
    
    private init() {}
    
    // ==========================================================
    // LANGCHAIN-STYLE RECURSIVE CHARACTER TEXT SPLITTER
    // ==========================================================
    /// Recursively splits text using a hierarchy of separators to preserve semantic context.
    func splitText(
        _ text: String,
        chunkSize: Int = 800,       // Maximum character length per chunk
        chunkOverlap: Int = 200,    // Target character overlap between chunks
        separators: [String] = ["\n\n", "\n", " ", ""]
    ) -> [String] {
        
        // 1. Clean out markdown image links so they don't break token counting
        let cleanedText = text.replacingOccurrences(of: "!\\[.*?\\]\\(.*?\\)", with: "", options: .regularExpression)
        
        return recursiveSplit(text: cleanedText, separators: separators, chunkSize: chunkSize, chunkOverlap: chunkOverlap)
    }
    
    private func recursiveSplit(text: String, separators: [String], chunkSize: Int, chunkOverlap: Int) -> [String] {
        // If the text is already under the target chunk size, return it as a standalone piece
        if text.count <= chunkSize {
            return [text]
        }
        
        // Default final fallback if we run out of structural separators
        var currentSeparator = ""
        var remainingSeparators: [String] = []
        
        // Pick the first available separator in the hierarchy
        if let first = separators.first {
            currentSeparator = first
            remainingSeparators = Array(separators.dropFirst())
        }
        
        // Split the text based on our current active separator
        let splits: [String]
        if currentSeparator.isEmpty {
            splits = text.map { String($0) } // Character-by-character split as absolute last resort
        } else {
            splits = text.components(separatedBy: currentSeparator)
        }
        
        var goodSplits: [String] = []
        var currentDoc: [String] = []
        var currentLen = 0
        
        for part in splits {
            // If a single part is still too large, recursively split it using the remaining separators
            if part.count > chunkSize {
                if !currentDoc.isEmpty {
                    goodSplits.append(currentDoc.joined(separator: currentSeparator))
                    currentDoc.removeAll()
                    currentLen = 0
                }
                
                let subSplits = recursiveSplit(text: part, separators: remainingSeparators, chunkSize: chunkSize, chunkOverlap: chunkOverlap)
                goodSplits.append(contentsOf: subSplits)
            } else {
                // If appending this part exceeds the limit, pack up the current doc chunk
                if currentLen + part.count + (currentDoc.isEmpty ? 0 : currentSeparator.count) > chunkSize {
                    if !currentDoc.isEmpty {
                        goodSplits.append(currentDoc.joined(separator: currentSeparator))
                    }
                    
                    // Handle overlap: retain previous elements that fit within the chunkOverlap buffer
                    while !currentDoc.isEmpty {
                        currentDoc.removeFirst()
                        let testLen = currentDoc.joined(separator: currentSeparator).count
                        if testLen <= chunkOverlap { break }
                    }
                    currentLen = currentDoc.joined(separator: currentSeparator).count
                }
                
                currentDoc.append(part)
                currentLen += part.count + (currentDoc.count > 1 ? currentSeparator.count : 0)
            }
        }
        
        if !currentDoc.isEmpty {
            goodSplits.append(currentDoc.joined(separator: currentSeparator))
        }
        
        // Final pass: filter out stray empty strings or white spaces
        return goodSplits.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    // ==========================================================
    // EMBEDDING INGESTION (Using the new Recursive Splitter)
    // ==========================================================
    func ingestDocument(text: String, notebookId: UUID, sourceId: UUID) {
        guard let embedder = embedder else { return }
        
        // Pass to our recursive text splitter (Uses character counts, perfect for exact memory limits)
        let chunks = splitText(text, chunkSize: 600, chunkOverlap: 150)
        
        for chunk in chunks {
            if let vector = embedder.vector(for: chunk) {
                let newChunk = VectorChunk(
                    id: UUID(),
                    notebookId: notebookId,
                    sourceId: sourceId,
                    text: chunk,
                    embedding: vector
                )
                vectorStore.append(newChunk)
            }
        }
        print("✅ Ingested into VectorDB using Recursive Splitter: \(chunks.count) semantically rich chunks indexed.")
    }
    
    // ==========================================================
    // RETRIEVAL ENGINE
    // ==========================================================
    func search(query: String, notebookId: UUID, topK: Int = 3) -> [String] {
        guard let embedder = embedder, let queryVector = embedder.vector(for: query) else { return [] }
        
        let scopedChunks = vectorStore.filter { $0.notebookId == notebookId }
        var scoredResults: [(chunk: VectorChunk, score: Double)] = []
        
        for chunk in scopedChunks {
            let similarity = cosineSimilarity(queryVector, chunk.embedding)
            scoredResults.append((chunk: chunk, score: similarity))
        }
        
        return scoredResults
            .sorted { $0.score > $1.score }
            .prefix(topK)
            .map { $0.chunk.text }
    }
    
    private func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        guard vectorA.count == vectorB.count else { return 0.0 }
        var dotProduct = 0.0
        vDSP_dotprD(vectorA, 1, vectorB, 1, &dotProduct, vDSP_Length(vectorA.count))
        
        var magnitudeA = 0.0
        vDSP_svesqD(vectorA, 1, &magnitudeA, vDSP_Length(vectorA.count))
        
        var magnitudeB = 0.0
        vDSP_svesqD(vectorB, 1, &magnitudeB, vDSP_Length(vectorB.count))
        
        let denominator = sqrt(magnitudeA) * sqrt(magnitudeB)
        return denominator == 0 ? 0.0 : dotProduct / denominator
    }
}
