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
}

extension Endpoint {
  var baseURL: String {
    return "https://whitepiano-codeserver.pe.kr"
  }
  
  var headers: [String: String]? {
    return [
      "Content-Type": "application/json",
      "Accept": "application/json"
    ]
  }
  
  var encoding: ParameterEncoding {
    switch method {
    case .get:
      return URLEncoding.default
    default:
      return JSONEncoding.default
    }
  }
  
  // URLRequestConvertible 구현
  func asURLRequest() throws -> URLRequest {
    let url = try baseURL.asURL().appendingPathComponent(path)
    var request = try URLRequest(url: url, method: method)
    request.headers = HTTPHeaders(headers ?? [:])
    
    return try encoding.encode(request, with: parameters)
  }
}
