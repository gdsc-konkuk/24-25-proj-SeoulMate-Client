//
//  UpdateUserProfileUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class UpdateUserProfileUseCase: UpdateUserProfileUseCaseProtocol {
  private let userRepository: UserRepositoryProtocol
  
  init(userRepository: UserRepositoryProtocol) {
    self.userRepository = userRepository
  }
  
  func execute(userName: String, birthYear: String, companion: String, purposes: [String]) -> AnyPublisher<Void, NetworkError> {
    return userRepository.updateProfile(
      userName: userName,
      birthYear: birthYear,
      companion: companion,
      purposes: purposes
    )
  }
}
