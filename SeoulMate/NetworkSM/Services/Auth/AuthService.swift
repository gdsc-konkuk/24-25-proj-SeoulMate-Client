//
//  AuthService.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
  func login(idToken: String) -> AnyPublisher<LoginResponse, NetworkError>
  func refreshToken(refreshToken: String, accessToken: String) -> AnyPublisher<RefreshTokenResponse, NetworkError>
}

final class AuthService: AuthServiceProtocol {
  private let networkProvider: NetworkProviderProtocol
  
  init(networkProvider: NetworkProviderProtocol) {
    self.networkProvider = networkProvider
  }
  
  func login(idToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
    let endpoint = AuthEndpoint.login(idToken: idToken)
    return networkProvider.request(endpoint)
  }
  
  func refreshToken(refreshToken: String, accessToken: String) -> AnyPublisher<RefreshTokenResponse, NetworkError> {
    let endpoint = AuthEndpoint.refreshToken(refreshToken: refreshToken, accessToken: accessToken)
    return networkProvider.request(endpoint)
  }
}
