//
//  UserRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class UserRepository: UserRepositoryProtocol {
  private let userService: UserServiceProtocol
  
  init(userService: UserServiceProtocol) {
    self.userService = userService
  }
  
  func getProfile() -> AnyPublisher<UserProfileResponse, NetworkError> {
    return userService.getProfile()
  }
  
  func updateProfile(userName: String, birthYear: String, companion: String, purposes: [String]) -> AnyPublisher<Void, NetworkError> {
    return userService.updateProfile(
      userName: userName,
      birthYear: birthYear,
      companion: companion,
      purposes: purposes
    )
  }
  
  func getHistories(userId: Int64, like: Bool?) -> AnyPublisher<UserHistoryResponse, NetworkError> {
    return userService.getHistories(userId: userId, like: like)
  }
}
