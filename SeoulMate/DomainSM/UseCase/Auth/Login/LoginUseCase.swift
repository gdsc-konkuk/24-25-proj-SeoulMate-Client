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
  
  func execute(idToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
    return authRepository.login(idToken: idToken)
  }
}
