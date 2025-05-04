//
//  UserModels.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

// MARK: - User Models
struct UserProfileResponse: Decodable {
  let userName: String
  let birthYear: String
  let companion: String
  let purposes: [String]
}

struct UpdateProfileRequest: Encodable {
  let userName: String
  let birthYear: String
  let companion: String
  let purposes: [String]
}

struct UserHistoryResponse: Decodable {
  let placeIds: [String]
}
