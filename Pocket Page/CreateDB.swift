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
    
    // Core safe addition to the store state
    private func appendChunk(_ chunk: VectorChunk) {
        self.vectorStore.append(chunk)
    }
    
    // ==========================================================
    // NON-BLOCKING ASYNC INGESTION
    // ==========================================================
    func ingestDocument(text: String, notebookId: UUID, sourceId: UUID) async {
        guard let embedder = self.embedder else { return }
        
        // Push heavy mathematical split & matrix work to a detached background worker thread
        await Task.detached(priority: .userInitiated) {
            let chunks = await self.splitText(text, chunkSize: 600, chunkOverlap: 150)
            
            for chunk in chunks {
                if let vector = embedder.vector(for: chunk) {
                    let newChunk = VectorChunk(
                        id: UUID(),
                        notebookId: notebookId,
                        sourceId: sourceId,
                        text: chunk,
                        embedding: vector
                    )
                    // Hop back to the actor context cleanly to append safely
                    await self.appendChunk(newChunk)
                }
            }
            print("✅ Ingested background tasks: \(chunks.count) chunks indexed.")
        }.value
    }
    
    // ==========================================================
    // PARALLELIZED RETRIEVAL ENGINE
    // ==========================================================
    func search(query: String, notebookId: UUID, topK: Int = 3) async -> [String] {
        guard let embedder = embedder, let queryVector = embedder.vector(for: query) else { return [] }
        
        let scopedChunks = vectorStore.filter { $0.notebookId == notebookId }
        if scopedChunks.isEmpty { return [] }
        
        
        return await Task.detached(priority: .high) {
            var scoredResults: [(chunk: VectorChunk, score: Double)] = []
            
            for chunk in scopedChunks {
                let similarity = await self.cosineSimilarity(queryVector, chunk.embedding)
                scoredResults.append((chunk: chunk, score: similarity))
            }
            
            return scoredResults
                .sorted { $0.score > $1.score }
                .prefix(topK)
                .map { $0.chunk.text }
        }.value
    
    }
    
    
    func splitText(
        _ text: String,
        chunkSize: Int = 800,
        chunkOverlap: Int = 200,
        separators: [String] = ["\n\n", "\n", " ", ""]
    ) -> [String] {
        let cleanedText = text.replacingOccurrences(of: "!\\[.*?\\]\\(.*?\\)", with: "", options: .regularExpression)
        return recursiveSplit(text: cleanedText, separators: separators, chunkSize: chunkSize, chunkOverlap: chunkOverlap)
    }
    
    private func recursiveSplit(text: String, separators: [String], chunkSize: Int, chunkOverlap: Int) -> [String] {
        if text.count <= chunkSize { return [text] }
        
        var currentSeparator = ""
        var remainingSeparators: [String] = []
        if let first = separators.first {
            currentSeparator = first
            remainingSeparators = Array(separators.dropFirst())
        }
        
        let splits = currentSeparator.isEmpty ? text.map { String($0) } : text.components(separatedBy: currentSeparator)
        var goodSplits: [String] = []
        var currentDoc: [String] = []
        var currentLen = 0
        
        for part in splits {
            if part.count > chunkSize {
                if !currentDoc.isEmpty {
                    goodSplits.append(currentDoc.joined(separator: currentSeparator))
                    currentDoc.removeAll()
                    currentLen = 0
                }
                let subSplits = recursiveSplit(text: part, separators: remainingSeparators, chunkSize: chunkSize, chunkOverlap: chunkOverlap)
                goodSplits.append(contentsOf: subSplits)
            } else {
                if currentLen + part.count + (currentDoc.isEmpty ? 0 : currentSeparator.count) > chunkSize {
                    if !currentDoc.isEmpty {
                        goodSplits.append(currentDoc.joined(separator: currentSeparator))
                    }
                    
                    
                    while currentDoc.count > 1 {
                        currentDoc.removeFirst()
                        let testLen = currentDoc.joined(separator: currentSeparator).count
                        if testLen <= chunkOverlap { break }
                    }
                }
                currentDoc.append(part)
                currentLen = currentDoc.joined(separator: currentSeparator).count
            }
        }
        
        if !currentDoc.isEmpty {
            goodSplits.append(currentDoc.joined(separator: currentSeparator))
        }
        return goodSplits.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    private func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        guard vectorA.count == vectorB.count, !vectorA.isEmpty else { return 0.0 }
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
