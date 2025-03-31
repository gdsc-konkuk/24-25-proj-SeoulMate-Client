//
//  AuthRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import Combine

enum AuthError: Error {
  case invalidCredentials
  case networkError
  case serverError
  case tokenExpired
  case unknown
}

protocol AuthRepositoryProtocol {
  func signInWithGoogle(idToken: String, accessToken: String) -> AnyPublisher<AuthResponse, AuthError>
  func refreshToken(refreshToken: String) -> AnyPublisher<AuthResponse, AuthError>
  func logout() -> AnyPublisher<Void, AuthError>
}

// TODO: ERD 설계 이후 수정
struct AuthResponse {
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  let userId: String
}
