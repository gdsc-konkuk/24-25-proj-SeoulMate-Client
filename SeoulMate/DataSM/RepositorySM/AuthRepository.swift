//
//  AuthRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import Combine

final class AuthRepository: AuthRepositoryProtocol {
  private let networkService: NetworkServiceProtocol
  private let baseURL: String
  
  init(networkService: NetworkServiceProtocol, baseURL: String) {
    self.networkService = networkService
    self.baseURL = baseURL
  }
  
  func signInWithGoogle(idToken: String, accessToken: String) -> AnyPublisher<AuthResponse, AuthError> {
    let endpoint = "\(baseURL)/auth/google-signin"
    let parameters: [String: Any] = [
      "idToken": idToken,
      "accessToken": accessToken
    ]
    
    return networkService.request(
      endpoint: endpoint,
      method: .post,
      parameters: parameters
    )
    .mapError { error -> AuthError in
      switch error {
      case let networkError as NetworkError:
        switch networkError {
        case .unauthorized:
          return .invalidCredentials
        case .serverError:
          return .serverError
        default:
          return .networkError
        }
      default:
        return .unknown
      }
    }
    .flatMap { data -> AnyPublisher<AuthResponse, AuthError> in
      do {
        let decoder = JSONDecoder()
        let response = try decoder.decode(AuthResponseDTO.self, from: data)
        return Just(response.toDomain())
          .setFailureType(to: AuthError.self)
          .eraseToAnyPublisher()
      } catch {
        return Fail(error: .unknown)
          .eraseToAnyPublisher()
      }
    }
    .eraseToAnyPublisher()
  }
  
  func refreshToken(refreshToken: String) -> AnyPublisher<AuthResponse, AuthError> {
    let endpoint = "\(baseURL)/auth/refresh-token"
    let parameters: [String: Any] = [
      "refreshToken": refreshToken
    ]
    
    return networkService.request(
      endpoint: endpoint,
      method: .post,
      parameters: parameters
    )
    .mapError { error -> AuthError in
      switch error {
      case let networkError as NetworkError:
        switch networkError {
        case .unauthorized:
          return .tokenExpired
        case .serverError:
          return .serverError
        default:
          return .networkError
        }
      default:
        return .unknown
      }
    }
    .flatMap { data -> AnyPublisher<AuthResponse, AuthError> in
      do {
        let decoder = JSONDecoder()
        let response = try decoder.decode(AuthResponseDTO.self, from: data)
        return Just(response.toDomain())
          .setFailureType(to: AuthError.self)
          .eraseToAnyPublisher()
      } catch {
        return Fail(error: .unknown)
          .eraseToAnyPublisher()
      }
    }
    .eraseToAnyPublisher()
  }
  
  func logout() -> AnyPublisher<Void, AuthError> {
    return Just(())
      .setFailureType(to: AuthError.self)
      .eraseToAnyPublisher()
  }
}

// MARK: - DTO

struct AuthResponseDTO: Decodable {
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  let userId: String
  
  func toDomain() -> AuthResponse {
    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      userId: userId
    )
  }
}
