//
//  GetRecommendedPlacesUseCase.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class GetRecommendedPlacesUseCase: GetRecommendedPlacesUseCaseProtocol {
  private let placeRepository: PlaceRepositoryProtocol
  
  init(placeRepository: PlaceRepositoryProtocol) {
    self.placeRepository = placeRepository
  }
  
  func execute(x: Double, y: Double) -> AnyPublisher<RecommendedPlacesResponse, NetworkError> {
    return placeRepository.getRecommendedPlaces(x: x, y: y)
  }
}
