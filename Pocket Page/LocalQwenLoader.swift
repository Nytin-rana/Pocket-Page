//
//  LocalQwenLoader.swift
//  Pocket Page
//
//  Created by Nytin Rana on 05/07/26.
//

import Foundation
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon

// ---------------------------------------------------------------------------
// The three imports below provide the types that the Hugging Face macro
// (#huggingFaceLoadModelContainer) and the underlying SDK need.
// Without them the compiler cannot resolve `HuggingFace`, `Tokenizers`,
// and `HubClient`.
// ---------------------------------------------------------------------------
import HuggingFace       // ← namespace for the HF SDK 
import Tokenizers        // ← tokenizer utilities 
import Hub      // ← client for downloading model weights from 🤗 Hub 

public class LocalQwenLoader {
    // Stores the wrapper container provided by the framework
    private var modelContainer: ModelContainer? // 
    
    public init() {} // 
    
public func loadModel() async throws {
    // Preferred path: Use Hugging Face unified loader to download and prepare the correct assets
    print("Checking/Downloading Qwen 2.5 0.5B model from Hugging Face...")

    let modelConfiguration = ModelConfiguration(id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit")

    let maxAttempts = 3
    var lastError: Error?

    for attempt in 1...maxAttempts {
        do {
            print("Attempt \(attempt)/\(maxAttempts): downloading/loading model...")
            self.modelContainer = try await #huggingFaceLoadModelContainer(configuration: modelConfiguration) { progress in
                let percent = Int(progress.fractionCompleted * 100)
                print("Downloading/Loading Progress: \(percent)%")
            }
            print("Model loaded successfully on attempt \(attempt).")
            lastError = nil
            break
        } catch {
            lastError = error
            print("Attempt \(attempt) failed to load model: \(error.localizedDescription)")
            if attempt < maxAttempts {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s backoff
            }
        }
    }

    if let err = lastError {
        print("All attempts to load the model failed: \(err)")
        throw err
    }

    print("Model loaded successfully on Apple Silicon GPU/CPU!")
    
    // --- Fallback reference (disabled): Local bundle loader retained for future offline packaging ---
    // If you later ship a converted, locally runnable model (e.g., GGUF/MLX container), you can
    // re-enable and use this block instead of downloading.
    /*
    print("Locating model files inside application bundle...")
    guard let bundlePath = Bundle.main.path(forResource: "Qwen2.5-0.5B-Instruct-4bit", ofType: nil) else {
        throw NSError(domain: "LocalQwenLoader", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "Model directory folder not found in app bundle resource layout."])
    }

    let modelURL = URL(fileURLWithPath: bundlePath)
    print("Loading local model from destination: \(modelURL.path)")

    do {
        let items = try FileManager.default.contentsOfDirectory(atPath: modelURL.path)
        print("Model folder contents (\(items.count) items):")
        for name in items.sorted() { print("- \(name)") }
    } catch {
        print("Warning: Unable to list contents of model folder: \(error)")
    }

    do {
        let urls = try FileManager.default.contentsOfDirectory(at: modelURL, includingPropertiesForKeys: nil)
        let ggufFiles = urls.filter { $0.pathExtension.lowercased() == "gguf" }
        guard !ggufFiles.isEmpty else {
            throw NSError(domain: "LocalQwenLoader", code: 405, userInfo: [NSLocalizedDescriptionKey: "No .gguf model weights found in bundle folder \(modelURL.lastPathComponent). Ensure the model weights are included as a folder reference."])
        }
        print("Found GGUF weights: \(ggufFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
    } catch {
        print("Warning: Failed to enumerate GGUF files: \(error)")
    }

    let tokenizerJSON = modelURL.appendingPathComponent("tokenizer.json")
    if !FileManager.default.fileExists(atPath: tokenizerJSON.path) {
        print("Note: tokenizer.json not found at \(tokenizerJSON.path). The loader will rely on embedded tokenizer metadata if available.")
    }

    do {
        self.modelContainer = try await LLMModelFactory.shared.loadContainer(
            from: modelURL,
            using: #huggingFaceTokenizerLoader()
        )
        print("Model loaded successfully from local bundle resources!")
    } catch {
        print("Failed to load container from \(modelURL.path): \(error)")
        throw error
    }
    */
}
    
    /// Generates a response using modern AsyncStream iteration
    public func generateResponse(
        prompt: String,
        systemPrompt: String = "You are a helpful assistant.", // 
        onTokenReceived: @escaping (String) -> Void // 
    ) async throws -> String {
        guard let container = modelContainer else { // 
            throw NSError(domain: "LocalQwenLoader", code: 401, // 
                          userInfo: [NSLocalizedDescriptionKey: "Model must be loaded first."]) // 
        }
        
        // --- FIX 1: Sanitize and enforce fallbacks for empty values to prevent C++ basic_string crashes ---
        let cleanSystemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeSystemPrompt = cleanSystemPrompt.isEmpty ? "You are a helpful assistant." : systemPrompt
        
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let safePrompt = cleanPrompt.isEmpty ? "Hello" : prompt
        
        // Preflight diagnostics to avoid null strings in native layer
        print("[Generate] Container ready:", modelContainer != nil)
        print("[Generate] systemPrompt length: \(safeSystemPrompt.count), prompt length: \(safePrompt.count))")
        if safeSystemPrompt.isEmpty || safePrompt.isEmpty {
            throw NSError(domain: "LocalQwenLoader", code: 406, userInfo: [NSLocalizedDescriptionKey: "Empty prompt or system prompt not allowed."])
        }
        
        // Format prompt using Qwen's ChatML schema structures
        let messages = [
            ["role": "system", "content": safeSystemPrompt], // 
            ["role": "user",   "content": safePrompt] // 
        ]
        
        // 1. Compile text into tokens inside the safe execution context
        let promptTokens: [Int] = try await container.perform { modelContext in // 
            return try modelContext.tokenizer.applyChatTemplate(messages: messages) // 
        }
        
        // 2. Convert the standard [Int] array into an MLXArray as expected by LMInput
        let mlxTokenArray = MLXArray(promptTokens) // 
        let lmInput = LMInput(tokens: mlxTokenArray) // 
        
        // 3. Define the sampling parameters
        let evalParameters = GenerateParameters( // 
            temperature: 0.7, // 
            topP: 0.9 // 
        )
        
        var fullResponse = "" // 
        
        let stream = try await container.generate(input: lmInput, parameters: evalParameters) // 
        
        for await generation in stream { // 
            switch generation { // 
            case .chunk(let text): // 
                fullResponse += text // 
                
                // --- FIX 2: Thread-safe coordination with the MainActor for rendering UI properties ---
                await MainActor.run {
                    onTokenReceived(text)
                }
            case .info(_): // 
                break // 
            case .toolCall(_): // 
                print("code") // 
            @unknown default: // 
                break // 
            }
        }
        
        return fullResponse // 
    }
}

