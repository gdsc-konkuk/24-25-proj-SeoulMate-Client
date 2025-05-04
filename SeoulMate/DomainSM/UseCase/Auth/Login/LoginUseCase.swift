//
//  LoginUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class LoginUseCase: LoginUseCaseProtocol {
  private let authRepository: AuthRepositoryProtocol
  
  init(authRepository: AuthRepositoryProtocol) {
    self.authRepository = authRepository
  }
  
  func execute(authorizationCode: String) -> AnyPublisher<LoginResponse, NetworkError> {
    return authRepository.login(authorizationCode: authorizationCode)
  }
}
