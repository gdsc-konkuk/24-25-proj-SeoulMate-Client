//
//  AuthModels.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

// MARK: - Auth Models
struct LoginRequest: Encodable {
  let authorizationCode: String
}

struct LoginResponse: Decodable {
  let accessToken: String
  let refreshToken: String
  let isFirstLogin: Bool
  let userId: Int64
}

struct RefreshTokenRequest: Encodable {
  let refreshToken: String
  let accessToken: String
}

struct RefreshTokenResponse: Decodable {
  let refreshToken: String
  let accessToken: String
}
