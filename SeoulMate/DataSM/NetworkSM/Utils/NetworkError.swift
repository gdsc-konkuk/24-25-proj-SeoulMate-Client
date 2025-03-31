//
//  NetworkError.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation

enum NetworkError: Error {
  case invalidURL
  case invalidRequest
  case noData
  case decodingError
  case unauthorized
  case serverError
  case unknown
}
