import Foundation
import SwiftData

@Model
class Notebook: Identifiable, Codable {
    var id: UUID
    var title: String
    var createdAt: Date
    var isFavorite: Bool
    
    // Relationships: If a Notebook is deleted, delete all its sources, notes, and chats
    @Relationship(deleteRule: .cascade) var sources: [DocumentSource] = []
    @Relationship(deleteRule: .cascade) var notes: [UserNote] = []
    @Relationship(deleteRule: .cascade) var chatSessions: [ChatSession] = []
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.isFavorite = false
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: CodingKey {
        case id, title, createdAt, isFavorite, sources, notes, chatSessions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        self.sources = try container.decode([DocumentSource].self, forKey: .sources)
        self.notes = try container.decode([UserNote].self, forKey: .notes)
        self.chatSessions = try container.decode([ChatSession].self, forKey: .chatSessions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(sources, forKey: .sources)
        try container.encode(notes, forKey: .notes)
        try container.encode(chatSessions, forKey: .chatSessions)
    }
}

// ==========================================================
// 1. SOURCES (The PDFs or Text Files the user imports)
// ==========================================================
@Model
class DocumentSource: Codable {
    var id: UUID
    var fileName: String
    var fileType: String // e.g., "pdf", "txt", "md"
    var importedAt: Date
    var rawTextContent: String // The extracted full text used for chunking
    
    
    var notebook: Notebook?
    
    init(fileName: String, fileType: String, rawTextContent: String) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.importedAt = Date()
        self.rawTextContent = rawTextContent
    }
    
    enum CodingKeys: CodingKey {
        case id, fileName, fileType, importedAt, rawTextContent
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileName = try container.decode(String.self, forKey: .fileName)
        self.fileType = try container.decode(String.self, forKey: .fileType)
        self.importedAt = try container.decode(Date.self, forKey: .importedAt)
        self.rawTextContent = try container.decode(String.self, forKey: .rawTextContent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(fileType, forKey: .fileType)
        try container.encode(importedAt, forKey: .importedAt)
        try container.encode(rawTextContent, forKey: .rawTextContent)
    }
}

// ==========================================================
// 2. NOTES (User-written thoughts inside the notebook)
// ==========================================================
@Model
class UserNote: Codable {
    var id: UUID
    var title: String
    var content: String
    var lastModified: Date
    
    var notebook: Notebook?
    
    init(title: String, content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.lastModified = Date()
    }
    
    enum CodingKeys: CodingKey {
        case id, title, content, lastModified
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(lastModified, forKey: .lastModified)
    }
}

// ==========================================================
// 3. CHATS (The conversation history for this specific notebook)
// ==========================================================
@Model
class ChatSession: Codable {
    var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage] = []
    
    var notebook: Notebook?
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.messages = []
    }
    
    enum CodingKeys: CodingKey {
        case id, title, messages
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.messages = try container.decode([ChatMessage].self, forKey: .messages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
    }
}

@Model
class ChatMessage: Codable {
    var id: UUID
    var text: String
    var isUser: Bool // true = User, false = Qwen 0.5B
    var timestamp: Date
    
    var session: ChatSession?
    
    init(text: String, isUser: Bool) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = Date()
    }
    
    enum CodingKeys: CodingKey {
        case id, text, isUser, timestamp
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.isUser = try container.decode(Bool.self, forKey: .isUser)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}





