

import Foundation
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import HuggingFace
import Tokenizers
import Hub

public class LocalQwenLoader {
    
    private var modelContainer: ModelContainer? //
    
    public init() {} //
    
    public func loadModel() async throws {
        Swift.print("Locating local Qwen 2.5 0.5B model from bundle...")
        
        guard let modelURL = Bundle.main.url(forResource: "Qwen2.5-0.5B-Instruct-4bit", withExtension: nil) else {
            let error = NSError(
                domain: "LocalQwenLoader",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Could not find 'Qwen2.5-0.5B-Instruct-4bit' folder in application bundle."]
            )
            Swift.print(error.localizedDescription)
            throw error
        }
        
        
        Swift.print("--- Investigating Folder Contents at Path: \(modelURL.path) ---")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: modelURL.path) {
            for file in contents {
                Swift.print("Found file: \(file)")
            }
        } else {
            Swift.print("❌ Could not read directory contents!")
        }
        Swift.print("-------------------------------------------------------")
        
        do {
            Swift.print("Loading local model files into memory...")
            
            self.modelContainer = try await LLMModelFactory.shared.loadContainer(
                from: modelURL,
                using: #huggingFaceTokenizerLoader()
            )
            
            Swift.print("Model loaded successfully from local bundle.")
        } catch {
            Swift.print("Failed to load local model: \(error.localizedDescription)")
            throw error
        }
    }
}
    
extension LocalQwenLoader {
    
    public func generateResponse(
        prompt: String,
        systemPrompt: String = "You are a helpful assistant.", //
        onTokenReceived: @escaping (String) -> Void //
    ) async throws -> String {
        guard let container = modelContainer else { //
            throw NSError(domain: "LocalQwenLoader", code: 401, //
                          userInfo: [NSLocalizedDescriptionKey: "Model must be loaded first."]) //
        }
        

        let cleanSystemPrompt = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeSystemPrompt = cleanSystemPrompt.isEmpty ? "You are a helpful assistant." : systemPrompt
        
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let safePrompt = cleanPrompt.isEmpty ? "Hello" : prompt
        
        
        Swift.print("[Generate] Container ready:", modelContainer != nil)
        Swift.print("[Generate] systemPrompt length: \(safeSystemPrompt.count), prompt length: \(safePrompt.count))")
        if safeSystemPrompt.isEmpty || safePrompt.isEmpty {
            throw NSError(domain: "LocalQwenLoader", code: 406, userInfo: [NSLocalizedDescriptionKey: "Empty prompt or system prompt not allowed."])
        }
        
        
        let messages = [
            ["role": "system", "content": safeSystemPrompt],
            ["role": "user",   "content": safePrompt]
        ]
        
        
        let promptTokens: [Int] = try await container.perform { modelContext in
            return try modelContext.tokenizer.applyChatTemplate(messages: messages)
        }
        
        
        let mlxTokenArray = MLXArray(promptTokens)
        let lmInput = LMInput(tokens: mlxTokenArray)
        
        
        let evalParameters = GenerateParameters(
            temperature: 0.7,
            topP: 0.9
        )
        
        var fullResponse = ""
        
        let stream = try await container.generate(input: lmInput, parameters: evalParameters)
        
        for await generation in stream {
            switch generation {
            case .chunk(let text):
                fullResponse += text
                
                
                await MainActor.run {
                    onTokenReceived(text)
                }
            case .info(_):
                break
            case .toolCall(_):
                Swift.print("code")
            @unknown default:
                break
            }
        }
        
        return fullResponse
    }
}
