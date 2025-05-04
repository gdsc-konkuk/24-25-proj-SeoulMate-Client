//
//  RefreshTokenUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol RefreshTokenUseCaseProtocol {
  func execute(refreshToken: String, accessToken: String) -> AnyPublisher<RefreshTokenResponse, NetworkError>
}
