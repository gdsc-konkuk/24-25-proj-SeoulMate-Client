//
//  NetworkError.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import Foundation

enum NetworkError: Error {
  case invalidURL
  case invalidResponse
  case invalidData
  case serverError(statusCode: Int)
  case decodingError(Error)
  case unauthorized
  case unknown(Error)
  
  var localizedDescription: String {
    switch self {
    case .invalidURL:
      return "잘못된 URL입니다."
    case .invalidResponse:
      return "서버 응답을 처리할 수 없습니다."
    case .invalidData:
      return "데이터가 유효하지 않습니다."
    case .serverError(let statusCode):
      return "서버 오류가 발생했습니다. (코드: \(statusCode))"
    case .decodingError(let error):
      return "데이터 변환 중 오류가 발생했습니다: \(error.localizedDescription)"
    case .unauthorized:
      return "인증이 필요합니다."
    case .unknown(let error):
      return "알 수 없는 오류가 발생했습니다: \(error.localizedDescription)"
    }
  }
}
