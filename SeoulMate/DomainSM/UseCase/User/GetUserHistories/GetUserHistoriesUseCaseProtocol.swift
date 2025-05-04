//
//  GetUserHistoriesUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol GetUserHistoriesUseCaseProtocol {
  func execute(userId: Int64, like: Bool?) -> AnyPublisher<UserHistoryResponse, NetworkError>
}
