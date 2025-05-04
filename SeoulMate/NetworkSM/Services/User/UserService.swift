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
    // 더미 프로필 응답 반환
    let dummyProfile = UserProfileResponse(
        userName: "Test User",
        birthYear: "1995",
        companion: "Alone",
        purposes: ["Activities", "Nature"]
    )
    
    return Just(dummyProfile)
        .setFailureType(to: NetworkError.self)
        .eraseToAnyPublisher()
    
//    let endpoint = UserEndpoint.getProfile
//    return networkProvider.request(endpoint)
  }
  
  func updateProfile(userName: String, birthYear: String, companion: String, purposes: [String]) -> AnyPublisher<Void, NetworkError> {
    let endpoint = UserEndpoint.updateProfile(
      userName: userName,
      birthYear: birthYear,
      companion: companion,
      purposes: purposes
    )
    
    // API가 response body가 없으면, Empty 타입 사용
    return networkProvider.request(endpoint)
      .map { (_: EmptyResponse) in () }
      .eraseToAnyPublisher()
  }
  
  func getHistories(userId: Int64, like: Bool?) -> AnyPublisher<UserHistoryResponse, NetworkError> {
    let endpoint = UserEndpoint.getHistories(userId: userId, like: like)
    return networkProvider.request(endpoint)
  }
}
