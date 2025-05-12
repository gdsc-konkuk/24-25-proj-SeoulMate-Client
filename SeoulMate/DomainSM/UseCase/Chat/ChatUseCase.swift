//
//  ChatUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

final class ChatUseCase: ChatUseCaseProtocol {
  private let repository: ChatRepositoryProtocol
  
  init(repository: ChatRepositoryProtocol) {
    self.repository = repository
  }
  
  func sendMessage(placeId: String, chatType: ChatType) async throws -> ChatResponseModel {
    return try await repository.sendMessage(placeId: placeId, chatType: chatType)
  }
}
