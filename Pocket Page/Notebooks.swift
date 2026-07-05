import Foundation
import SwiftData

@Model
class Notebook {
    var id: UUID
    var title: String
    var createdAt: Date
    
    // Relationships: If a Notebook is deleted, delete all its sources, notes, and chats
    @Relationship(deleteRule: .cascade) var sources: [DocumentSource] = []
    @Relationship(deleteRule: .cascade) var notes: [UserNote] = []
    @Relationship(deleteRule: .cascade) var chatSessions: [ChatSession] = []
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
    }
}

// ==========================================================
// 1. SOURCES (The PDFs or Text Files the user imports)
// ==========================================================
@Model
class DocumentSource {
    var id: UUID
    var fileName: String
    var fileType: String // e.g., "pdf", "txt", "md"
    var importedAt: Date
    var rawTextContent: String // The extracted full text used for chunking
    
    // Links back to the parent notebook
    var notebook: Notebook?
    
    init(fileName: String, fileType: String, rawTextContent: String) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.importedAt = Date()
        self.rawTextContent = rawTextContent
    }
}

// ==========================================================
// 2. NOTES (User-written thoughts inside the notebook)
// ==========================================================
@Model
class UserNote {
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
}

// ==========================================================
// 3. CHATS (The conversation history for this specific notebook)
// ==========================================================
@Model
class ChatSession {
    var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage] = []
    
    var notebook: Notebook?
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.messages = []
    }
}

@Model
class ChatMessage {
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
}

