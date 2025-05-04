//
//  CommonModels.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation

struct EmptyResponse: Decodable {}

struct ErrorResponse: Decodable {
  let status: Int
  let error: String
  let message: String
  let path: String
  let timestamp: String
}
