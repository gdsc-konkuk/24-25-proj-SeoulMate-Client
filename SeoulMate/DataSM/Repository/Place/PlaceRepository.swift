//
//  PlaceRepository.swift
//  SeoulMate
//
//  Created by 박성근 on 5/4/25.
//

import Foundation
import Combine

final class PlaceRepository: PlaceRepositoryProtocol {
  private let placeService: PlaceServiceProtocol
  
  init(placeService: PlaceServiceProtocol) {
    self.placeService = placeService
  }
  
  func getRecommendedPlaces(x: Double, y: Double) -> AnyPublisher<RecommendedPlacesResponse, NetworkError> {
    return placeService.getRecommendedPlaces(x: x, y: y)
  }
  
  func getLikedPlaces() -> AnyPublisher<LikedPlacesResponse, NetworkError> {
    return placeService.getLikedPlaces()
  }
  
  func updateLikeStatus(placeId: String, like: Bool) -> AnyPublisher<EmptyResponse, NetworkError> {
    return placeService.updateLikeStatus(placeId: placeId, like: like)
  }
}
