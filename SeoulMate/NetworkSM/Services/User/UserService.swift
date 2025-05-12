//
//  UserService.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol UserServiceProtocol {
  func getProfile() -> AnyPublisher<UserProfileResponse, NetworkError>
  func updateProfile(userName: String, birthYear: String, companion: String, purposes: [String]) -> AnyPublisher<Void, NetworkError>
  func getHistories(userId: Int64, like: Bool?) -> AnyPublisher<UserHistoryResponse, NetworkError>
}

final class UserService: UserServiceProtocol {
  private let networkProvider: NetworkProviderProtocol
  
  init(networkProvider: NetworkProviderProtocol) {
    self.networkProvider = networkProvider
  }
  
  func getProfile() -> AnyPublisher<UserProfileResponse, NetworkError> {
    let endpoint = UserEndpoint.getProfile
    return networkProvider.request(endpoint)
  }
  
  func updateProfile(userName: String, birthYear: String, companion: String, purposes: [String]) -> AnyPublisher<Void, NetworkError> {
    let endpoint = UserEndpoint.updateProfile(
      name: userName,
      birthYear: birthYear,
      companion: companion,
      purpose: purposes
    )
    
    return networkProvider.request(endpoint)
      .map { (_: EmptyResponse) in () }
      .eraseToAnyPublisher()
  }
  
  func getHistories(userId: Int64, like: Bool?) -> AnyPublisher<UserHistoryResponse, NetworkError> {
    let endpoint = UserEndpoint.getHistories(userId: userId, like: like)
    return networkProvider.request(endpoint)
  }
}
