import Foundation
import CoreData

public protocol ChatRepositoryProtocol {
    func startNewConversation()
    func endCurrentConversation()
    func fetchMessages() -> [ChatMessage]
    func fetchPreviousConversation(after: Date?) -> Conversation?
    func fetchMessages(from: Conversation) -> [ChatMessage]
    func addMessage(text: String, sender: String)
} 