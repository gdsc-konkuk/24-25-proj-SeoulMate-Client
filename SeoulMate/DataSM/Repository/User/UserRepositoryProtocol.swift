//
//  UserRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol UserRepositoryProtocol {
  func getProfile() -> AnyPublisher<UserProfileResponse, NetworkError>
  
  func updateProfile(
    userName: String,
    birthYear: String,
    companion: String,
    purposes: [String]
  ) -> AnyPublisher<Void, NetworkError>
  
  func getHistories(
    userId: Int64,
    like: Bool?
  ) -> AnyPublisher<UserHistoryResponse, NetworkError>
}
