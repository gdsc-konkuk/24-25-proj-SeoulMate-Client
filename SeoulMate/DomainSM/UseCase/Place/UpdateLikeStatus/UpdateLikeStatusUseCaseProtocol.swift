//
//  UpdateLikeStatusUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation
import Combine

protocol UpdateLikeStatusUseCaseProtocol {
  func execute(placeId: String, like: Bool) -> AnyPublisher<EmptyResponse, NetworkError>
}
