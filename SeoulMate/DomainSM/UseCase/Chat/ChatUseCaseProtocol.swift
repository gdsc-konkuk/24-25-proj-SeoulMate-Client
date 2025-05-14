//
//  ChatUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation
import Combine

public protocol ChatUseCaseProtocol {
  func sendMessage(placeId: String, chatType: ChatType, text: String) async throws -> ChatResponseModel
}
