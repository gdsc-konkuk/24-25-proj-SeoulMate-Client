//
//  ChatMessage.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

// MARK: - Message Model
public struct ChatMessage {
  let text: String
  let sender: String
  let timestamp: Date
  let chatType: ChatType
}

public enum ChatType: String, Codable {
  case REPLY = "REPLY"
  case FREE_CHAT = "FREE_CHAT"
  case FITNESS_SCORE = "FITNESS_SCORE"
}

public struct ChatRequestModel: Codable {
  let placeId: String?
  let chatType: ChatType
}

public struct ChatResponseModel: Codable {
  let reply: String?
  let explanation: String?
  let score: String?
  
  enum CodingKeys: String, CodingKey {
    case reply
    case explanation
    case score
  }
}
