//
//  GetUserProfileUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class GetUserProfileUseCase: GetUserProfileUseCaseProtocol {
  private let userRepository: UserRepositoryProtocol
  
  init(userRepository: UserRepositoryProtocol) {
    self.userRepository = userRepository
  }
  
  func execute() -> AnyPublisher<UserProfileResponse, NetworkError> {
    return userRepository.getProfile()
  }
}
