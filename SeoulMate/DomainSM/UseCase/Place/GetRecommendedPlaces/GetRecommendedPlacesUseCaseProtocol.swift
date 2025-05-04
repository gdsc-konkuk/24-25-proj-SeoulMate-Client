//
//  GetRecommendedPlacesUseCaseProtocol.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

protocol GetRecommendedPlacesUseCaseProtocol {
  func execute(x: Double, y: Double) -> AnyPublisher<RecommendedPlacesResponse, NetworkError>
}
