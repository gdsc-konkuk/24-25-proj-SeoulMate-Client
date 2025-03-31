//
//  NetworkService.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import Combine
import Alamofire

final class NetworkService: NetworkServiceProtocol {
  private let tokenStorage: TokenStorageProtocol
  
  init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage
  }
  
  func request(
    endpoint: String,
    method: HTTPMethod,
    parameters: [String: Any]?
  ) -> AnyPublisher<Data, Error> {
    
    // Alamofire HTTP 메소드로 변환
    let afMethod = getAlamofireMethod(from: method)
    
    // 헤더 설정
    var headers: HTTPHeaders = [
      "Content-Type": "application/json"
    ]
    
    // 토큰이 있다면 Authorization 헤더 추가
    if let accessToken = tokenStorage.getAccessToken() {
      headers["Authorization"] = "Bearer \(accessToken)"
    }
    
    // Alamofire 요청 생성
    return AF.request(
      endpoint,
      method: afMethod,
      parameters: parameters,
      encoding: JSONEncoding.default,
      headers: headers
    )
    .validate()
    .publishData()
    .tryMap { response in
      switch response.result {
      case .success(let data):
        return data
      case .failure(let error):
        let statusCode = response.response?.statusCode ?? 0
        
        switch statusCode {
        case 401:
          throw NetworkError.unauthorized
        case 500...599:
          throw NetworkError.serverError
        default:
          throw error
        }
      }
    }
    .mapError { error in
      if let afError = error as? AFError {
        return self.handleAFError(afError)
      }
      
      if let networkError = error as? NetworkError {
        return networkError
      }
      
      return NetworkError.unknown
    }
    .eraseToAnyPublisher()
  }
  
  // HTTPMethod에서 Alamofire.HTTPMethod로 변환하는 헬퍼 메소드
  private func getAlamofireMethod(from method: HTTPMethod) -> Alamofire.HTTPMethod {
    switch method {
    case .get:
      return .get
    case .post:
      return .post
    case .put:
      return .put
    case .delete:
      return .delete
    }
  }
  
  // AFError를 NetworkError로 변환하는 헬퍼 메소드
  private func handleAFError(_ error: AFError) -> NetworkError {
    switch error {
    case .invalidURL:
      return .invalidURL
    case .responseValidationFailed(let reason):
      switch reason {
      case .unacceptableStatusCode(let code):
        if code == 401 {
          return .unauthorized
        } else if code >= 500 && code < 600 {
          return .serverError
        }
        return .unknown
      default:
        return .unknown
      }
    case .responseSerializationFailed:
      return .decodingError
    default:
      return .unknown
    }
  }
}
