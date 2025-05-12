//
//  UserEndpoint.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire

enum UserEndpoint: Endpoint {
  case getProfile
  case updateProfile(name: String, birthYear: String, companion: String, purpose: [String])
  case getHistories(userId: Int64, like: Bool?)
  
  var path: String {
    switch self {
    case .getProfile:
      return "/users/me"
    case .updateProfile:
      return "/users/me"
    case .getHistories(let userId, _):
      return "/users/\(userId)/histories"
    }
  }
  
  var method: HTTPMethod {
    switch self {
    case .getProfile, .getHistories:
      return .get
    case .updateProfile:
      return .post
    }
  }
  
  var parameters: Parameters? {
    switch self {
    case .getProfile:
      return nil
      
    case .updateProfile(let userName, let birthYear, let companion, let purposes):
      return [
        "name": userName,
        "birthYear": birthYear,
        "companion": companion,
        "purpose": purposes
      ]
      
    case .getHistories(_, let like):
      guard let like = like else { return nil }
      return ["like": like]
    }
  }
}
