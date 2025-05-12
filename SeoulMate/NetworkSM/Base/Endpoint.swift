//
//  Endpoint.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation
import Alamofire

protocol Endpoint: URLRequestConvertible {
  var baseURL: String { get }
  var path: String { get }
  var method: HTTPMethod { get }
  var headers: [String: String]? { get }
  var parameters: Parameters? { get }
  var encoding: ParameterEncoding { get }
  var requiresAuth: Bool { get }
}

extension Endpoint {
  var baseURL: String {
    return "https://whitepiano-codeserver.pe.kr"
  }
  
  var requiresAuth: Bool {
    return true // 기본적으로 인증이 필요하다고 가정
  }
  
  var headers: [String: String]? {
    var headers: [String: String] = [
      "Content-Type": "application/json",
      "Accept": "application/json"
    ]
    
    if requiresAuth {
      if let accessToken = UserDefaults.standard.string(forKey: "accessToken") {
        headers["Authorization"] = "Bearer \(accessToken)"
      }
    }
    
    return headers
  }
  
  var encoding: ParameterEncoding {
    switch method {
    case .get:
      return URLEncoding.default
    default:
      return JSONEncoding.default
    }
  }
  
  func asURLRequest() throws -> URLRequest {
    let url = try baseURL.asURL().appendingPathComponent(path)
    var request = try URLRequest(url: url, method: method)
    request.headers = HTTPHeaders(headers ?? [:])
    
    return try encoding.encode(request, with: parameters)
  }
}
