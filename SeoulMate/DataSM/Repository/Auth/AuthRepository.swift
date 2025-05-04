//
//  AuthRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class AuthRepository: AuthRepositoryProtocol {
  private let authService: AuthServiceProtocol
  
  init(authService: AuthServiceProtocol) {
    self.authService = authService
  }
  
  func login(authorizationCode: String) -> AnyPublisher<LoginResponse, NetworkError> {
    return authService.login(authorizationCode: authorizationCode)
  }
  
  func refreshToken(refreshToken: String, accessToken: String) -> AnyPublisher<RefreshTokenResponse, NetworkError> {
    return authService.refreshToken(refreshToken: refreshToken, accessToken: accessToken)
  }
}
