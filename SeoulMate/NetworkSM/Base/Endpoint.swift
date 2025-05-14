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
  var queryParameters: Parameters? { get }
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
  
  var queryParameters: Parameters? {
    return nil
  }
  
  func asURLRequest() throws -> URLRequest {
    var url = try baseURL.asURL().appendingPathComponent(path)
    
    // Add query parameters if any
    if let queryParams = queryParameters {
      let queryItems = queryParams.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
      var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
      components?.queryItems = queryItems
      if let finalURL = components?.url {
        url = finalURL
      }
    }
    
    var request = try URLRequest(url: url, method: method)
    request.headers = HTTPHeaders(headers ?? [:])
    
    return try encoding.encode(request, with: parameters)
  }
}
