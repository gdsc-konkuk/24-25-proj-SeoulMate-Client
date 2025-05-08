//
//  ChatMessageRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 5/5/25.
//

import Foundation
import CoreData

final class ChatMessageRepository {
  static let shared = ChatMessageRepository()
  private let context = CoreDataStack.shared.mainContext

  // MARK: - Conversation
  func createConversation(id: String = UUID().uuidString, placeName: String, companion: String, purposes: [String], startedAt: Date = Date()) -> Conversation? {
    let conversation = Conversation(context: context)
    conversation.id = id
    conversation.placeName = placeName
    conversation.companion = companion
    conversation.purposes = purposes
    conversation.startedAt = startedAt
    saveContext()
    return conversation
  }

  func fetchConversations(limit: Int? = nil, offset: Int = 0) -> [Conversation] {
    let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
    if let limit = limit { request.fetchLimit = limit }
    request.fetchOffset = offset
    do {
      return try context.fetch(request)
    } catch {
      print("[CoreData] fetchConversations error: \(error)")
      return []
    }
  }

  func deleteConversation(id: String) {
    let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", id)
    do {
      let results = try context.fetch(request)
      for obj in results { context.delete(obj) }
      saveContext()
    } catch {
      print("[CoreData] deleteConversation error: \(error)")
    }
  }

  // MARK: - ChatMessage
  func addMessage(to conversation: Conversation, text: String, sender: String, timestamp: Date = Date()) -> ChatMessage? {
    let message = ChatMessage(context: context)
    message.id = UUID()
    message.text = text
    message.sender = sender
    message.timestamp = timestamp
    message.conversation = conversation
    saveContext()
    return message
  }

  func fetchMessages(for conversation: Conversation, limit: Int? = nil, offset: Int = 0) -> [ChatMessage] {
    let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
    request.predicate = NSPredicate(format: "conversation == %@", conversation)
    request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
    if let limit = limit { request.fetchLimit = limit }
    request.fetchOffset = offset
    do {
      return try context.fetch(request)
    } catch {
      print("[CoreData] fetchMessages error: \(error)")
      return []
    }
  }

  func deleteMessage(id: UUID) {
    let request: NSFetchRequest<ChatMessage> = ChatMessage.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
    do {
      let results = try context.fetch(request)
      for obj in results { context.delete(obj) }
      saveContext()
    } catch {
      print("[CoreData] deleteMessage error: \(error)")
    }
  }

  // MARK: - Save
  private func saveContext() {
    CoreDataStack.shared.saveContext()
  }
} 
