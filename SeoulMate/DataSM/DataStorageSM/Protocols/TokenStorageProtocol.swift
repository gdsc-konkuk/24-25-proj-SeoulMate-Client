//
//  TokenStorageProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation

protocol TokenStorageProtocol {
  func saveTokens(accessToken: String, refreshToken: String, userId: String, expiresIn: Int)
  func getAccessToken() -> String?
  func getRefreshToken() -> String?
  func getUserId() -> String?
  func getTokenExpiration() -> Date?
  func isTokenValid() -> Bool
  func clearTokens()
}
