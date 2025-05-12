//
//  ChatRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation

protocol ChatRepositoryProtocol {
  func sendMessage(placeId: String, chatType: ChatType) async throws -> ChatResponseModel
}
