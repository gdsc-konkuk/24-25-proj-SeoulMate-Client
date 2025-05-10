//
//  AuthRepositoryProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol AuthRepositoryProtocol {
  func login(idToken: String) -> AnyPublisher<LoginResponse, NetworkError>
  func refreshToken(refreshToken: String, accessToken: String) -> AnyPublisher<RefreshTokenResponse, NetworkError>
}
