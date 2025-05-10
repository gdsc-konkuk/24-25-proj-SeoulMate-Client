//
//  AuthModels.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

// MARK: - Auth Models
struct LoginRequest: Codable {
  let idToken: String
}

struct LoginResponse: Codable {
  let accessToken: String
  let refreshToken: String
  let isFirstLogin: Bool
  let userId: String
}

struct RefreshTokenRequest: Codable {
  let refreshToken: String
  let accessToken: String
}

struct RefreshTokenResponse: Codable {
  let refreshToken: String
  let accessToken: String
}
