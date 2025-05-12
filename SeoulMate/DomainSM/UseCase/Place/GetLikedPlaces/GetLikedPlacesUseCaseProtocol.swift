//
//  GetLikedPlacesUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/12/25.
//

import Foundation
import Combine

protocol GetLikedPlacesUseCaseProtocol {
  func execute() -> AnyPublisher<LikedPlacesResponse, NetworkError>
}
