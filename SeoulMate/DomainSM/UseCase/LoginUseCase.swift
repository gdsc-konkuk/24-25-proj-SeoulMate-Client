//
//  LoginUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import Combine

protocol LoginUseCaseProtocol {
  func executeGoogleLogin(idToken: String, accessToken: String) -> AnyPublisher<Void, AuthError>
  func executeTokenRefresh() -> AnyPublisher<Void, AuthError>
  func executeLogout() -> AnyPublisher<Void, AuthError>
}

final class LoginUseCase: LoginUseCaseProtocol {
  private let authRepository: AuthRepositoryProtocol
  private let tokenStorage: TokenStorageProtocol
  
  init(
    authRepository: AuthRepositoryProtocol,
    tokenStorage: TokenStorageProtocol
  ) {
    self.authRepository = authRepository
    self.tokenStorage = tokenStorage
  }
  
  func executeGoogleLogin(idToken: String, accessToken: String) -> AnyPublisher<Void, AuthError> {
    return authRepository.signInWithGoogle(idToken: idToken, accessToken: accessToken)
      .flatMap { [weak self] response -> AnyPublisher<Void, AuthError> in
        guard let self = self else {
          return Fail(error: AuthError.unknown).eraseToAnyPublisher()
        }
        
        // 토큰 저장
        self.tokenStorage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          userId: response.userId,
          expiresIn: response.expiresIn
        )
        
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func executeTokenRefresh() -> AnyPublisher<Void, AuthError> {
    guard let refreshToken = tokenStorage.getRefreshToken() else {
      return Fail(error: AuthError.tokenExpired).eraseToAnyPublisher()
    }
    
    return authRepository.refreshToken(refreshToken: refreshToken)
      .flatMap { [weak self] response -> AnyPublisher<Void, AuthError> in
        guard let self = self else {
          return Fail(error: AuthError.unknown).eraseToAnyPublisher()
        }
        
        // 새 토큰 저장
        self.tokenStorage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          userId: response.userId,
          expiresIn: response.expiresIn
        )
        
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
  
  func executeLogout() -> AnyPublisher<Void, AuthError> {
    return authRepository.logout()
      .flatMap { [weak self] _ -> AnyPublisher<Void, AuthError> in
        guard let self = self else {
          return Fail(error: AuthError.unknown).eraseToAnyPublisher()
        }
        
        self.tokenStorage.clearTokens()
        return Just(()).setFailureType(to: AuthError.self).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }
}
