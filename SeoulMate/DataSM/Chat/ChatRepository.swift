import Foundation
import CoreData

public final class ChatRepository: ChatRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext
    
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.mainContext
    }
    
    public func startNewConversation() {
        let conversation = Conversation(context: context)
        conversation.startedAt = Date()
        conversation.id = UUID().uuidString
        coreDataStack.saveContext()
    }
    
    public func endCurrentConversation() {
        // 현재 대화 종료 시 특별한 처리가 필요하지 않음
    }
    
    public func fetchMessages() -> [ChatMessage] {
        let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
    
    public func fetchPreviousConversation(after: Date?) -> Conversation? {
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        if let after = after {
            request.predicate = NSPredicate(format: "startedAt < %@", after as NSDate)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching previous conversation: \(error)")
            return nil
        }
    }
    
    public func fetchMessages(from conversation: Conversation) -> [ChatMessage] {
        let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "conversation == %@", conversation)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching messages from conversation: \(error)")
            return []
        }
    }
    
    public func addMessage(text: String, sender: String) {
        let message = ChatMessage(context: context)
        message.text = text
        message.sender = sender
        message.timestamp = Date()
        message.id = UUID()
        
        // 현재 활성화된 대화에 메시지 추가
        let conversationRequest: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        conversationRequest.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        conversationRequest.fetchLimit = 1
        
        do {
            if let conversation = try context.fetch(conversationRequest).first {
                message.conversation = conversation
            }
            coreDataStack.saveContext()
        } catch {
            print("Error adding message: \(error)")
        }
    }
} 
