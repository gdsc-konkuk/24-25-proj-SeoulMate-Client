//
//  GetUserHistoriesUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class GetUserHistoriesUseCase: GetUserHistoriesUseCaseProtocol {
  private let userRepository: UserRepositoryProtocol
  
  init(userRepository: UserRepositoryProtocol) {
    self.userRepository = userRepository
  }
  
  func execute(userId: Int64, like: Bool?) -> AnyPublisher<UserHistoryResponse, NetworkError> {
    return userRepository.getHistories(userId: userId, like: like)
  }
}
