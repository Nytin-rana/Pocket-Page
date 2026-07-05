//
//  LocalQwenLoader.swift
//  Pocket Page
//
//  Created by Nytin Rana on 05/07/26.
//

import Foundation
import MLXHuggingFace
import MLX
import MLXLLM
import MLXLMCommon

public class LocalQwenLoader {
    // Stores the wrapper container provided by the framework
    private var modelContainer: ModelContainer?
    
    public init() {}
    
    /// Downloads (if needed) and loads the Qwen 2.5 0.5B model automatically
    public func loadModel() async throws {
        print("Checking/Downloading Qwen 2.5 0.5B model from Hugging Face...")
        
        // 1. Define the model configuration
        let modelConfiguration = ModelConfiguration(id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit")
        
        // 2. Load directly using the 3.x unified ecosystem macro
        // This eliminates the need to import MLXHuggingFace or Tokenizers explicitly
        self.modelContainer = try await #huggingFaceLoadModelContainer(configuration: modelConfiguration) { progress in
            let percent = Int(progress.fractionCompleted * 100)
            print("Downloading/Loading Progress: \(percent)%")
        }
        
        print("Model loaded successfully on Apple Silicon GPU/CPU!")
    }
    
    /// Generates a response using modern AsyncStream iteration
    public func generateResponse(
        prompt: String,
        systemPrompt: String = "You are a helpful assistant.",
        onTokenReceived: @escaping (String) -> Void
    ) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(domain: "LocalQwenLoader", code: 401, userInfo: [NSLocalizedDescriptionKey: "Model must be loaded first."])
        }
        
        // Format prompt using Qwen's ChatML schema structures
        let messages = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]
        
        // 1. Compile text into tokens inside the safe execution context
        let promptTokens: [Int] = try await container.perform { modelContext in
            return try modelContext.tokenizer.applyChatTemplate(messages: messages)
        }
        
        // 2. Convert the standard [Int] array into an MLXArray as expected by LMInput
        let mlxTokenArray = MLXArray(promptTokens)
        let lmInput = LMInput(tokens: mlxTokenArray)
        
        // 3. Define the sampling parameters
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
                DispatchQueue.main.async {
                    onTokenReceived(text)
                }
            case .info(_):
                break
            case .toolCall(_):
               print("code")
            @unknown default:
                break
            }
        }
        
        return fullResponse
    }
}
