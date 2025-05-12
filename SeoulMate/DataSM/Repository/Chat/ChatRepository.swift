//
//  ChatRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

final class ChatRepository: ChatRepositoryProtocol {
  private let chatService: ChatServiceProtocol
  
  init(chatService: ChatServiceProtocol) {
    self.chatService = chatService
  }
  
  func sendMessage(placeId: String, chatType: ChatType) async throws -> ChatResponseModel {
    return try await chatService.sendMessage(placeId: placeId, chatType: chatType)
  }
} 
