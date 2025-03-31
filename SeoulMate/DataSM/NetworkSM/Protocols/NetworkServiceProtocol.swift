//
//  NetworkServiceProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 3/31/25.
//

import Foundation
import Combine

protocol NetworkServiceProtocol {
  func request(
    endpoint: String,
    method: HTTPMethod,
    parameters: [String: Any]?
  ) -> AnyPublisher<Data, Error>
}
