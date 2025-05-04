//
//  UpdateUserProfileUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol UpdateUserProfileUseCaseProtocol {
  func execute(userName: String, birthYear: String, companion: String, purposes: [String]) -> AnyPublisher<Void, NetworkError>
}
