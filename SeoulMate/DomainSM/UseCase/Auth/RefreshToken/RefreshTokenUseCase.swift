//
//  RefreshTokenUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class RefreshTokenUseCase: RefreshTokenUseCaseProtocol {
  private let authRepository: AuthRepositoryProtocol
  
  init(authRepository: AuthRepositoryProtocol) {
    self.authRepository = authRepository
  }
  
  func execute(refreshToken: String, accessToken: String) -> AnyPublisher<RefreshTokenResponse, NetworkError> {
    return authRepository.refreshToken(refreshToken: refreshToken, accessToken: accessToken)
  }
}
