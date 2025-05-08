import Foundation
import CoreData

public final class ChatUseCase: ChatUseCaseProtocol {
    private let repository: ChatRepositoryProtocol
    
    public init(repository: ChatRepositoryProtocol) {
        self.repository = repository
    }
    
    public func startNewConversation() {
        repository.startNewConversation()
    }
    
    public func endCurrentConversation() {
        repository.endCurrentConversation()
    }
    
    public func fetchMessages() -> [ChatMessage] {
        repository.fetchMessages()
    }
    
    public func fetchPreviousConversation(after: Date?) -> Conversation? {
        repository.fetchPreviousConversation(after: after)
    }
    
    public func fetchMessages(from conversation: Conversation) -> [ChatMessage] {
        repository.fetchMessages(from: conversation)
    }
    
    public func addMessage(text: String, sender: String) {
        repository.addMessage(text: text, sender: sender)
    }
} 
