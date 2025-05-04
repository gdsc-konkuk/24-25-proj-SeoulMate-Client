//
//  AuthEndpoint.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire

enum AuthEndpoint: Endpoint {
  case login(authorizationCode: String)
  case refreshToken(refreshToken: String, accessToken: String)
  
  var path: String {
    switch self {
    case .login:
      return "/auth/login"
    case .refreshToken:
      return "/auth/refresh"
    }
  }
  
  var method: HTTPMethod {
    switch self {
    case .login, .refreshToken:
      return .post
    }
  }
  
  var parameters: Parameters? {
    switch self {
    case .login(let authorizationCode):
      return ["authorizationCode": authorizationCode]
      
    case .refreshToken(let refreshToken, let accessToken):
      return [
        "refreshToken": refreshToken,
        "accessToken": accessToken
      ]
    }
  }
}
